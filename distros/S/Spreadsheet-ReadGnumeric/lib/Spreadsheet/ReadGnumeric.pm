# -*- mode: perl; -*-
#
# Spreadsheet reader for Gnumeric format that returns a
# Spreadsheet::Read-compatible data structure.
#
# Documentation below "__END__".
#
# [created.  -- rgr, 26-Dec-22.]
#

package Spreadsheet::ReadGnumeric;

use 5.010;

use strict;
use warnings;

use XML::Parser::Lite;
use Spreadsheet::Gnumeric::StyleRegion;

our $VERSION = '0.2';

use parent qw(Spreadsheet::Gnumeric::Base);

BEGIN {
    Spreadsheet::ReadGnumeric->define_instance_accessors
	(# User options to control parsing.
	 qw(gzipped_p cells rc attr merge minimal_attributes convert_colors),
	 # Intermediate data structures for sheet parsing.
	 qw(sheet style_regions style_attributes),
	 # XML parsing internals.
	 qw(current_elt current_attrs chars namespaces element_stack));
}

sub new {
    my ($class, @options) = @_;

    my $self = $class->SUPER::new(@options);
    $self->{_cells} //= 1;
    $self->{_rc} //= 1;
    $self->{_convert_colors} //= 1;
    return $self;
}

sub sheets {
    # Read-only slot.  Make sure the sheets slot is initialized.
    my ($self) = @_;

    my $sheets = $self->{_sheets};
    unless ($sheets) {
	# [I'm afraid this is just cargo-culting here.  -- rgr, 27-Dec-22.]
	my $parser_data = { parser => __PACKAGE__,
			    type => 'gnumeric',
			    version => $VERSION };
	my $attrs = { parsers => [ $parser_data ],
		      %$parser_data,
		      error => undef };
	$sheets = [ $attrs ];
	$self->{_sheets} = $sheets;
    }
    return $sheets;
}

### XML parsing support.

# This is because XML::Parser::Lite callbacks are called with the Expat object
# and not us, so we must bind $Self dynamically around the parsing operation.
use vars qw($Self);

sub _context_string {
    my ($self) = @_;

    my $stack = $self->element_stack;
    return $self->current_elt
	unless $stack;
    return join(' ', (map { $_->[0]; } @$stack), $self->current_elt);
}

sub _decode_xlmns_name {
    # Figure out whether we have a Gnumeric element name.
    my ($self, $elt_name) = @_;

    my ($ns_prefix, $base_elt_name) = $elt_name =~ /^([^:]+):([^:]+)$/;
    if ($ns_prefix) {
	# See if the prefix is the one we want.
	my $url = $self->namespaces->{$ns_prefix};
	if ($url && $url eq "http://www.gnumeric.org/v10.dtd") {
	    # Belongs to the Gnumeric schema.
	    return ($base_elt_name, 1);
	}
	else {
	    # It's something else.
	    return ($elt_name, 0);
	}
    }
    else {
	# Assume unqualified names belong to Gnumeric (even though we've never
	# seen any).
	return ($elt_name, 1);
    }
}

sub _handle_start {
    my ($expat, $elt, @attrs) = @_;
    my $attrs = { @attrs };

    # Establish the new namespace scope.  We do this first, because it may
    # define the prefix used on this element.
    my $old_ns_scope = $Self->namespaces || { };
    my $new_ns_scope = { %$old_ns_scope };
    if (grep { /^xmlns:(.*)$/ } keys(%$attrs)) {
	# Copy so as not to clobber the outer scope.
	$new_ns_scope = { %$old_ns_scope };
	for my $attr (keys(%$attrs)) {
	    if ($attr =~ /^xmlns:(.*)$/) {
		my $ns_prefix = $1;
		$new_ns_scope->{$ns_prefix} = $attrs->{$attr};
	    }
	}
    }
    $Self->namespaces($new_ns_scope);

    # Stack the outer context.
    my $stack = $Self->element_stack || [ ];
    push(@$stack, [ $Self->current_elt, $Self->current_attrs,
		    $Self->chars, $old_ns_scope ])
	if $Self->current_elt;
    $Self->element_stack($stack);

    # Install the new element context.
    my ($decoded_name) = $Self->_decode_xlmns_name($elt);
    $Self->current_elt($decoded_name);
    $Self->current_attrs($attrs);
    $Self->chars('');
}

sub _handle_char {
    # Just collect them in our "chars" slot.
    my ($expat, $chars) = @_;

    if (0) {
	warn("handle_char:  '$chars' in ", $Self->_context_string, "\n")
	    unless $chars =~ /^\s*$/;
    }
    $Self->{_chars} .= $chars;
}

sub _handle_end {
    my ($expat, $raw_elt_name) = @_;

    # Process the completed element.
    my ($elt_name, $gnumeric_p) = $Self->_decode_xlmns_name($raw_elt_name);
    if ($gnumeric_p) {
	my $method = "_process_${elt_name}_elt";
	$Self->$method($Self->chars, %{$Self->current_attrs})
	    if $Self->can($method);
    }

    # Restore the outer element context.
    my $stack = $Self->element_stack;
    return
	unless @$stack;
    my ($elt, $attrs, $chars, $old_ns_scope) = @{pop(@$stack)};
    $Self->current_elt($elt);
    $Self->current_attrs($attrs);
    $Self->chars($chars);
    $Self->namespaces($old_ns_scope);
}

### Utility routines.

sub _decode_alpha {
    # Note that this is one-based, so "A" is 1, "Z" is 26, and "AA" is 27.  But
    # there is no consistent zero digit, so this is not really base 26; if it
    # were, "A" should be zero and "Z" should overflow to "BA".
    my ($alpha) = @_;

    if (length($alpha) == 0) {
	return 0;
    }
    else {
	return (26 * _decode_alpha(substr($alpha, 0, -1))
		+ ord(lc(substr($alpha, -1))) - ord('a') + 1)
    }
}

sub _decode_cell_name {
    my ($cell_name) = @_;

    my ($alpha, $digits) = $cell_name =~ /^([a-zA-Z]+)(\d+)$/;
    return
	unless $alpha;
    return (_decode_alpha($alpha), 0 + $digits);
}

sub _encode_cell_name {
    # Note that $value is one-based, so 1 corresponds to "A".  See the note
    # under _decode_alpha.
    my ($value) = @_;

    return ($value <= 26
	    ? chr(ord('A') + $value - 1)
	    : (_encode_cell_name(int(($value - 1) / 26))
	       . _encode_cell_name(1 + ($value - 1) % 26)));
}

### Spreadsheet parsing

sub _parse_stream {
    # Create a new XML::Parser::Lite instance, use it to drive the parsing of
    # $xml_stream (which we assume is uncompressed), and return the resulting
    # spreadsheet object.
    my ($self, $xml_stream) = @_;

    my $parser = XML::Parser::Lite->new
	(Style => 'Stream',
	 Handlers => { Start => \&_handle_start,
		       End   => \&_handle_end,
		       Char  => \&_handle_char });
    local $Self = $self;
    $parser->parse(join('', <$xml_stream>));
    return $self->sheets;
}

sub stream_gzipped_p {
    my ($self, $stream, $file) = @_;

    # The point of the gzipped_p slot is to allow callers to suppress the gzip
    # test if the stream is not seekable.
    my $gzipped_p = $self->gzipped_p;
    if (! defined($gzipped_p)) {
	read($stream, my $block, 2) or do {
	    my $file_msg = 'from stream';
	    $file_msg = " from '$file'";
	    die "$self:  Failed to read opening bytes$file_msg:  $!";
	};
	# Test if gzipped (/usr/share/misc/magic).
	$gzipped_p = $block eq "\037\213";
	seek($stream, 0, 0);
    }
    return $gzipped_p;
}

sub parse {
    my ($self, $input) = @_;

    my $stream;
    if (ref($input)) {
	# Assume it's a stream.
	$stream = $input;
    }
    elsif ($input =~ m/\A(\037\213|<\?xml)/) {
	# $input is literal content, compressed and/or XML.
	open($stream, '<', \$input);
    }
    else {
	open($stream, '<', $input)
	    or die "$self:  Failed to open '$input':  $!";
    }
    binmode($stream, ':gzip')
	if $self->stream_gzipped_p($stream, ref($input) ? () : $input);
    binmode($stream, ':encoding(UTF-8)');
    return $self->_parse_stream($stream);
}

sub _process_Name_elt {
    # Record the sheet name.
    my ($self, $name) = @_;

    # Find the enclosing element, which needs to be "Sheet".
    my $stack = $self->element_stack;
    return
	unless $stack->[@$stack-1][0] eq 'Sheet';
    my $sheets = $self->sheets;
    $sheets->[0]{sheet}{$name} = @$sheets;
    $self->{_sheet}{label} = $name;
}

sub _process_MaxCol_elt {
    my ($self, $maxcol) = @_;

    $self->{_sheet}{mincol} = 1;
    $self->{_sheet}{maxcol} = 1 + $maxcol;
}

sub _process_MaxRow_elt {
    my ($self, $maxrow) = @_;

    return
	unless $maxrow;
    $self->{_sheet}{minrow} = 1;
    $self->{_sheet}{maxrow} = 1 + $maxrow;
}

sub _process_Merge_elt {
    # We don't care about MergedRegions, as that's just a container.
    my ($self, $text) = @_;

    push(@{$self->{_sheet}{merged}},
	 [ map { _decode_cell_name($_) } split(':', $text) ])
	if $self->attr;
}

sub _process_Cell_elt {
    my ($self, $text, %keys) = @_;

    # Ignore empty cells.
    return
	unless $text;
    # Both $row and $col are zero-based; the cell matrix is one-based.
    my ($row, $col) = ($keys{Row}, $keys{Col});
    $self->{_sheet}{cell}[$col + 1][$row + 1] = $text
	if $self->rc;
    $self->{_sheet}{_encode_cell_name($col + 1) . ($row + 1)} = $text
	if $self->cells;
    $self->{_sheet}{attr}[$col + 1][$row + 1]
	= $self->find_style_for_cell($col, $row)
	    if $self->attr;
}

sub _process_Sheet_elt {
    # Add $self->sheet to $self->sheets.
    my ($self, $text, %keys) = @_;

    my $sheets = $self->sheets;
    my $attrs = $sheets->[0];
    my $indx = $attrs->{sheets} = @$sheets;
    my $sheet = $self->sheet;
    $self->{_sheet}{cell}[0] = [ ]	# for consistency.
	if $self->{_sheet}{cell};
    push(@$sheets, $sheet);
    $sheet->{indx} = $indx;
    my $attr = $self->attr;
    if ($attr) {
	$sheet->{style_regions} = $self->style_regions
	    if $attr eq 'keep';
	$self->style_regions([ ]);
	# Distribute non-minimal attributes.
	unless ($self->minimal_attributes) {
	    for my $col (1 .. $sheet->{maxcol}) {
		for my $row (1 .. $sheet->{maxrow} || 0) {
		    $self->{_sheet}{attr}[$col][$row]
			||= $self->find_style_for_cell($col - 1, $row - 1);
		}
	    }
	}
	# Distribute merging information.
	my $merged = $sheet->{merged};
	if ($merged) {
	    my $attrs = $sheet->{attr};
	    my $merge_p = $self->merge;
	    for my $merge (@$merged) {
		my ($col1, $row1, $col2, $row2) = @$merge;
		my $base_cell_name = _encode_cell_name($col1) . $row1;
		my $merge_flag = $merge_p ? $base_cell_name : 1;
		my $base_cell_contents = ($self->rc
					  ? $sheet->{cell}[$col1][$row1]
					  : $sheet->{$base_cell_name});
		for my $col ($col1 .. $col2) {
		    for my $row ($row1 .. $row2) {
			my $cell_attrs
			    = ($attrs->[$col][$row]
			       || $self->find_style_for_cell($col - 1,
							     $row - 1)
			       || { });
			# Copy the hash so we don't accidentally mark other
			# cells as merged due to shared structure.
			$cell_attrs = { %$cell_attrs };
			$cell_attrs->{merged} = $merge_flag;
			$attrs->[$col][$row] = $cell_attrs;
			# When $merge_p, also copy cell contents.
			if ($merge_p) {
			    $sheet->{cell}[$col][$row] = $base_cell_contents
				if $self->rc;
			    my $cell_name = _encode_cell_name($col) . $row;
			    $sheet->{$cell_name} = $base_cell_contents
				if $self->cells;
			}
		    }
		}
	    }
	}
    }
    $self->sheet({ });
}

## Parsing cell style attributes

sub _convert_identity {
    # We assume this is 0 or 1.
    my ($value) = @_;

    return $value;
}

sub _convert_align {
    # This is a string which we truncate and downcase -- and hope the caller
    # can figure it out, since Gnumeric seems to use non-standard values.
    my ($value) = @_;

    return $value =~ /^GNM_.ALIGN_(.*)$/ ? lc($1) : lc($value);
}

sub _convert_color {
    my ($color) = @_;

    my $convert_primary = sub {
	# Pad and/or truncate the value.
	my ($value) = @_;

	my $len = length($value);
	if ($len <= 2) {
	    # Less than #xFF we round to zero.
	    return '00';
	}
	elsif ($len == 3) {
	    return '0' . substr($value, 0, 1);
	}
	else {
	    return substr($value, 0, 2);
	}
    };

    return join('', '#', map { $convert_primary->($_); } split(':', $color));
}

my %style_conversion_map
    = (Back => [ bgcolor => \&_convert_color, 1 ],
       Bold => [ bold    => \&_convert_identity ],
       # Font is not an attribute.
       Fore => [ fgcolor => \&_convert_color, 1 ],
       Format => [ format  => \&_convert_identity ],
       HAlign => [ halign  => \&_convert_align ],
       Hidden => [ hidden  => \&_convert_identity ],
       Indent => [ indent => \&_convert_identity ],
       Italic => [ italic => \&_convert_identity ],
       Locked => [ locked => \&_convert_identity ],
       PatternColor => [ pattern_color => \&_convert_color, 1 ],
       Rotation => [ rotation => \&_convert_identity ],
       Script => [ script => \&_convert_identity ],
       Shade => [ shade => \&_convert_identity ],
       ShrinkToFit => [ shrink_to_fit => \&_convert_identity ],
       Unit => [ size => \&_convert_identity ],
       StrikeThrough => [ strike_through => \&_convert_identity ],
       Underline => [ uline => \&_convert_identity ],
       VAlign => [ valign => \&_convert_align ],
       WrapText => [ wrap => \&_convert_identity ]);

sub _convert_attributes {
    # It is a useful coincidence that the cell metadata Spreadsheet::Read
    # calls attributes are stored in XML attributes by Gnumeric.  So we convert
    # Gnumeric cell attributes to Spreadsheet::Read cell attributes.
    my ($self, $cell_attributes, $gnumeric_attributes) = @_;

    my $convert_colors = $self->convert_colors;
    for my $name (keys(%$gnumeric_attributes)) {
	my $value = $gnumeric_attributes->{$name};
	my $conversion = $style_conversion_map{$name};
	my ($converted_name, $converter, $color_p)
	    = ($conversion ? @$conversion : (lc($name), \&_convert_identity));
	$converter = \&_convert_identity
	    if $color_p && ! $convert_colors;
	my $converted_value = $converter->($value);
	$cell_attributes->{$converted_name} = $converted_value;
    }
}

sub _process_Font_elt {
    # Process a font definition.  This is contained inside <Style>, so it ends
    # before it, so we initialize the style_attributes slot here, then </Style>
    # fills it out.
    my ($self, $font_name, %keys) = @_;

    return
	unless $self->attr;
    my $style_attributes = { font => $font_name };
    $self->_convert_attributes($style_attributes, \%keys);
    $self->style_attributes($style_attributes);
}

sub _process_Style_elt {
    # Process style attributes.
    my ($self, $text, %keys) = @_;

    return
	unless $self->attr;
    my $style_attributes = $self->style_attributes or die;
    $self->_convert_attributes($style_attributes, \%keys);
}

sub find_style_for_cell {
    # Assuming $self->attr is true, find the style region for ($col, $row) and
    # return its attribute hash.
    my ($self, $col, $row) = @_;

    my $found;
    for my $style_region (@{$self->{_style_regions}}) {
	if ($style_region->start_col <= $col
	        && $col <= $style_region->end_col
	    && $style_region->start_row <= $row
	        && $row <= $style_region->end_row) {
	    die "duplicate at ($col, $row)"
		# style regions are supposed to be disjoint; enable this for
		# extra paranoia.
		if 0 && $found;
	    $found = $style_region;
	}
    }
    return $found && $found->style_attributes;
}

sub _process_StyleRegion_elt {
    # Collect a style region for the style attributes we have just defined.
    my ($self, $text, %keys) = @_;

    return
	unless $self->attr;
    my $style_region = Spreadsheet::Gnumeric::StyleRegion->new
	(start_col => $keys{startCol}, end_col => $keys{endCol},
	 start_row => $keys{startRow}, end_row => $keys{endRow},
	 style_attributes => $self->style_attributes);
    push(@{$self->{_style_regions}}, $style_region);
}

1;

__END__

=head1 NAME

Spreadsheet::ReadGnumeric - read a Gnumeric file, return Spreadsheet::Read

=head1 VERSION

Version 0.2

=head1 SYNOPSIS

    use Spreadsheet::ReadGnumeric;

    my $reader = Spreadsheet::ReadGnumeric->new
        (rc => 1, cells => 1);	# these are the defaults
    my $book = $reader->parse('spreadsheet.gnumeric');
    my $n_sheets = $book->[0]{sheets};
    my $sheet_1 = $book->[1];
    my $b12 = $sheet_1->{B12};
    # or equivalently:
    my $b12 = $sheet_1->{cell}[2][12];
    say $b12;	# => "not a vitamin", e.g.

=head1 DESCRIPTION

Given a source of saved Gnumeric data, C<Spreadsheet::ReadGnumeric>
parses it and returns the result in the same format as
C<Spreadsheet::Read>.  In fact, C<Spreadsheet::Read> has a few more
bells and whistles, such as transposing the resulting sheets and
providing an object-oriented interface to the resulting data, so it
may be easier to access this module through C<Spreadsheet::Read>, even
if you only want to parse Gnumeric data.

Note that Gnumeric only saves raw cell values, and not their
formatted versions.  In particular, Gnumeric saves expressions, and not
expression values, never mind formatted expression values.
Even the expressions are sometimes encoded in a way
that C<Spreadsheet::ReadGnumeric> cannot not completely unparse, so
the returned data structure will look less well populated than the
spreadsheet does in Gnumeric.  See the "ExprID" TODO item below.

=head1 METHODS

After creating an instance with L</new>, call L</parse> with a file
name, a stream, or a string containing the spreadsheet data.
The L</attr>, L</cells>, L</convert_colors> L</gzipped_p>, L</merge>,
L</minimal_attributes>, and L</rc> slots control how
C<Spreadsheet::ReadGnumeric> parses its input.  They may also be used
as initializer keywords to the L</new> method.

The rest of these deal with the XML parsing mechanism and are probably
not of interest (unless you need to write a subclass in order to
extract more information).

=head3 attr

Slot that, if true, directs the parsing methods to retain style
information in the returned C<< $sheet->{attr} >> array of each sheet.
If the value of this slot is "keep", an arrayref of each sheet's
C<Spreadsheet::Gnumeric::StyleRegion> instances is saved in
C<< $sheet->{style_regions} >>.

The C<attr> value is normally supplied to the C<new> method as an
initializer.  See the C<Spreadsheet::Read> L<Cell
Attributes|https://metacpan.org/pod/Spreadsheet::Read#Cell-Attributes>
documentation for details of the resulting attributes.  See
L<Spreadsheet::Gnumeric::StyleRegion> for details of how attribute
conversion is performed.

See also the L</merge> slot, which requests additional processing of
cell merge information.

=head3 cells

Slot that contains the value of the C<Spreadsheet::Read> "cells"
option.  When true, this populates the C<< $sheet->{$cell_name} >>
with the corresponding cell data, where C<$cell_name> is an
alphanumeric cell name such as "B17" or "AA3".  Defaults to a true
value.

=head3 chars

Slot that contains the text content of an XML element being parsed.

=head3 convert_colors

Slot that contains a boolean which, if defined and true, causes
Gnumeric colors to be converted to the more common HTML-style format.
Gnumeric specifies colors as RGB triples using hex numbers of one to
four digits for each primary color, separated by colons, so that white
is "FFFF:FFFF:FFFF", and cyan is "0:FC00:F800".  Conversion pads each
primary to four digits, takes the first two, and prepends "#",
producing "#FFFFFF" for white and "#00FCF8" for cyan.

For C<Spreadsheet::Read> compatibility, the default is true.  This
value is ignored unless L</attr> is true.

=head3 current_attrs

Slot that contains the attribute of an element being parsed.

=head3 current_elt

Slot that contains the name of an element being parsed, including any
namespace prefix (see C<namespaces>).

=head3 element_stack

Slot that contains an arrayref that is a stack of containing element
contexts.  The last entry in this is the parent of the current element
being parsed, and is itself an arrayref of the values of

    [ current_elt, current_attrs, chars, namespaces ]

while that containing element was being parsed.

=head3 find_style_for_cell

Given zero-based column and row indices, look in L</style_regions> for
a suitable C<Spreadsheet::Gnumeric::StyleRegion> instance, and return
its attribute hash.

=head3 gzipped_p

Slot that determines whether C<parse> will test whether its
argument is gzipped.  There are three possibilities:  Undefined, other
false, and true.  If undefined, then C<parse> will open the file,
make the test, and then reset the stream to the beginning (see
L</stream_gzipped_p>).  Otherwise, C<parse> will take the
caller's word for it.

=head3 merge

Slot that requests additional processing of cell merging information.
If true, (a) the value of the C<merged> attribute for merged cells is
the name of the upper left corner of the rectangle of merged cells,
and (b) the contents and attributes of that upper-left cell are copied
into all of the others.  The default is false.

This flag is ignored unless the L</attr> slot is also true.

=head3 minimal_attributes

Slot that, if true, causes attributes to be filled in only for cells
that have content, i.e. actually appear as a C<< <Cell> >> in the file
with a nonempty string string.  Otherwise, attributes are filled in
for the full C<< $sheet->{maxrow} >> vs C<< $sheet->{maxcol} >> array.
The default is false.

This flag is ignored unless the L</attr> slot is also true.

=head3 namespaces

Slot that contains a hash of namespace prefix to defining URL, for all
prefixes in scope.  These are never modified by side effect, so that
they can be copied into inner scopes.  We use this to decide whether
any given name is really in the schema we care about.

=head3 new

Creates a new C<Spreadsheet::ReadGnumeric> instance.  Keywords are any
of the method names listed as slots.

=head3 parse

Given an input source, reads it and returns the
C<Spreadsheet::Read>-compatible data structure, constructed according
to the options set up at instantiation time.  If the L</gzipped_p>
slot is defined and true or the content starts with gzip magic (see
L</stream_gzipped_p>), which is the normal state of saved Gnumeric
spreadsheets, it is uncompressed while being read.  If C<gzipped_p> is
not defined, the stream is read to see how it starts and then rewound.

The input can be a reference (which is taken to be an open stream), a
file name, or a literal string that contains the data.  If given an
non-seekable stream, the C<stream_gzipped_p> slot must be defined in
order to skip the test for compressed input.

=head3 rc

Slot that contains the value of the C<Spreadsheet::Read> "rc" option.
When true, this populates the C<< $sheet->{cell}[$col][$row] >>
arrays.  Defaults to a true value.

=head3 sheet

Slot that contains the sheet currently under construction.

=head3 sheets

Read-only slot that contains the resulting
C<Spreadsheet::Read>-compatible data structure.  This slot is
initialized when its value is first requested; it is expected that the
value is then updated by side-effect.

=head3 stream_gzipped_p

Given a stream open to the start of the data and an optional file
name, determine whether we need to uncompress the data and then reset
the stream back to the beginning.  If the C<gzipped_p> slot is
defined, then we just return that and leave the stream untouched.  The
file name is only used for error messages.

=head3 style_attributes

Internal slot used to store a hashref of spreadsheet attributes during
parsing.

=head3 style_regions

Slot that contains an arrayref of
C<Spreadsheet::Gnumeric::StyleRegion> instances, built by the style
parsing code for each sheet and cleared when the sheet is completed.

=head1 INTERNALS

C<Spreadsheet::ReadGnumeric> uses C<XML::Parser::Lite> to decode the
XML into its component elements, calling the C<_process_Foo_elt>
method at each C<< </Foo> >> closing tag (explicit or implicit), where
"Foo" is the case-sensitive element name.  If no such method exists,
the element is ignored, though its content may already have been
processed.  For instance, we don't care about C<< <Sheets> >> because
it exists only as a container for C<< <Sheet> >> elements, which we do
process.

Elements with XMLNS prefixes (using the ":" separator) must be
associated with the Gnumeric schema in order to be visible to this
parsing mechanism.  Elements without prefixes are assumed to be part
of the Gnumeric schema (but the only Gnumeric files I've seen so far
use prefixes on all elements).  Note that element names stored in
C<current_elt> and C<element_stack> have already been stripped of any
Gnumeric-specific prefixes.

When the C<_process_Foo_elt> method is called, it can examine the
L</current_attrs> hash for its attributes and the L</chars> string for
its character content; all element content will already have been
processed.  If necessary, it can examine the L</element_stack> slot to
check context.  For example, C<_process_Name_elt> needs to do this
because it only processes Sheet element names.  The C<element_stack>
also makes the attributes of enclosing elements available.

Consequently, extending C<Spreadsheet::ReadGnumeric> to extract more
information out of Gnumeric files should be a simple matter of
defining a subclass with suitable C<_process_*_elt> methods that
examine their context, extract their content, and stuff the result
into the C<sheet> and/or C<sheets> slot values accordingly.  At least
that's my theory, and I'm sticking to it.

=head1 TODO

Note that the "clip", "strip", and "pivot" options of
C<Spreadsheet::Read> are handled by its C<_clipsheets> sub, so I do
not intend to do anything about them here.

These are not in any necessary order of importance.

=over 4

=item *

Handle "ExprID".  These are Cell attributes, e.g.:

        <gnm:Cell Row="10" Col="7" ExprID="1"/>

Looking at the test data, they seem to indicate that the missing
content is the expression in the earlier cell with the same ID after
shifting by the location difference.  This requires parsing equations,
though.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-spreadsheet-readgnumeric at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-ReadGnumeric>.

=head1 SEE ALSO

=over 4

=item The Gnumeric Spreadsheet

See L<http://www.gnumeric.org/>.

=item Spreadsheet::Read

Frontend to multiple spreadsheet formats, with additional options for
manipulating the result, plus the option to give them object
capabilities.  This module also describes the output data structure in
depth.

=item The Gnumeric File Format

This is a PDF file by David Gilbert dated 2001-11-05, available at
L<https://www.jfree.org/jworkbook/download/gnumeric-xml.pdf> (GFDL).
I am not aware of any more recent version.

=back

=head1 AUTHOR

Bob Rogers C<< <rogers at rgrjr.com> >>, based heavily on the
C<Spreadsheet::Read> architecture.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Bob Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
