package Parse::FixedLength;
use strict;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use Carp;
use vars qw($VERSION $DELIM $DEBUG);
$VERSION   = '5.39';
$DELIM = ":";
$DEBUG = 0;

#=======================================================================
sub import {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    for (@_) {
        $class->import($class->_all_modules()), last if $_ eq ':all';
        eval "use ${class}::$_";
        confess $@ if $@;
    }
}

sub _all_modules {
    my $self = shift;
    eval "use File::Spec";
    confess $@ if $@;
    my %modules;
    for my $dir (@INC) {
        my $pfl_dir = File::Spec->catdir($dir, 'Parse', 'FixedLength');
        next unless -d $pfl_dir;
        opendir(DIR, $pfl_dir) or confess "Can't read $pfl_dir: $!";
        for (readdir DIR) {
            my $module = $_;
            next unless $module =~ s/\.pm$//;
            $modules{$module} = undef;
        }
        closedir DIR;
    }
    keys %modules;
}

sub new {
    # Do the cargo cult OO construction thing
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $format = shift;
    unless (ref $format) {
        my $newclass = "${class}::${format}";
        my $result = eval { $newclass->new(@_)};
        return $result unless $@;
        confess $@ unless $@ =~ /Can't locate object method/;
        # Assume we need to require this format
        $class->import($format);
        return $newclass->new(@_);
    }
    confess "Format argument not an array ref"
        unless UNIVERSAL::isa($format, 'ARRAY');
    my $self = bless {}, $class;
    my $params = shift || {};
    confess "Params argument not a hash ref"
        if defined $params and ! UNIVERSAL::isa($params, 'HASH');
    my $delim = exists $params->{'delim'} ? $params->{'delim'} : $DELIM;
    $self->{DELIM} = $delim;
    my $delim_re = qr/\Q$delim/;
    confess "Delimiter argument must be one character" unless length($delim)==1;
    if (exists $$params{all_lengths}) {
        my $all = $$params{all_lengths};
        confess "all_lengths must be a positive integer"
            unless $all and $all =~ /^\d+$/ and $all > 0;
        $format = [ map { local $_=$_; s/$delim_re.*//;
                         "${_}${delim}$$params{all_lengths}"
                        } @$format ];
    }
    my $spaces = $params->{'spaces'} ? 'a' : 'A';
    my $is_hsh = $self->{IS_HSH} = _chk_format_type($format, $delim_re);

    # Convert hash-like array to delimited array
    $format = [ map  { $$format[$_].$delim.$$format[$_+1] }
                grep { not $_ % 2 } 0..$#$format
              ] if $is_hsh;
    my ($names, $alengths, $hlengths, $justify, $length, $fmts) =
        _parse_format($format, $delim_re, $params);

    $self->{NAMES} = $names;
    $self->{UNPACK} = join '', @{$fmts}{@$names};
    ( $self->{PACK} = $self->{UNPACK} ) =~ tr/a/A/;
    $self->{LENGTH} = $length;
    @$self{qw(TFIELDS TNAMES)} = ([], []);
    # Save justify fields no matter what for benefit of dumper()
    if (%$justify) {
        $self->{JFIELDS} = $justify;
        $self->{JUST} = 1 unless $$params{no_justify};
        @$self{qw(TFIELDS TNAMES TPAD)} = _trim_info($self);
        $self->{TRIM} = 1 if $$params{trim};
    }
    $self->{LENGTHS} = $hlengths;
    $self->{FMTS} = $fmts;
    $self->{DEBUG} = exists $$params{'debug'} ?
        ref($$params{'debug'}) ? $$params{'debug'} : \*STDOUT : $DEBUG;

    # Make slot to parse data into
    my $ref = $params->{href} || {};
    @$ref{@{$self->names}} = undef;
    $self->{DATA} = $ref;
    $self->hash_to_obj($self->{DATA}) unless $params->{no_bless};

    $self;
}

# Determine which format we have, the delimited array ref
# or the hash-like array ref.
# There must be delimiters in either all of the elements or none in
# alternating elements with an even number of elements.
# Assume what we have from the first element.
sub _chk_format_type {
    my ($format, $delim) = @_;
    my $is_hsh = 1 unless $$format[0] =~ $delim;
    confess"Odd number of name/length pairs or missing delimiter on first field"
        if $is_hsh and @$format % 2;
    for my $i (0..$#$format) {
        my $field = $$format[$i];
        if ($field =~ $delim) {
            confess "Field $field contains delimiter" if $is_hsh and not $i % 2;
        } else { confess "Field $field is missing delimiter" unless $is_hsh }
    }
    return $is_hsh;
}

sub _parse_format {
    my ($format, $delim, $params) = @_;
    my (@names, @lengths, %lengths, %justify, %dups, %fmts);
    my $dups_ok = $$params{autonum};
    my $all_dups_ok;
    if ($dups_ok) {
        if (UNIVERSAL::isa($dups_ok, 'ARRAY')) {
            @dups{@$dups_ok} = undef;
        } else { $all_dups_ok = 1 }
    }
    my $length = 0;
    my $nxt = 1;
    for (@$format) {
        my ($name, $tmp_len, $start, $end) = split $delim;
        _chk_start_end($name, $nxt, $start, $end) unless $$params{no_validate};
        $name = _chk_dups(
            $name, \@names, \%fmts,
            \%lengths, \%justify, \%dups, $dups_ok, $all_dups_ok
        );
        push @names, $name;
        # The results of the inner-parens is not guaranteed unless the
        # outer parens match, so we do it this way
        if ( $tmp_len =~ /^\d/ ) {
          my ($len, $is_just, $chr) = $tmp_len =~ /^(\d+)((?:R(.?))?)$/
              or confess "Bad length $tmp_len for field $name";
          $len > 0 or confess "Length must be > 0 for field $name";
          unless ( $$params{no_validate} ) {
            if (defined $end) {
              confess "Bad length or end for field $name"
                unless $end == $start + $len - 1;
            }
          }
          $justify{$name} = ($chr eq '') ? ' ' : $chr if $is_just;
          $lengths{$name} = $len;
          push @lengths, $len;
          $length += $len;
          $nxt = $end + 1 if defined $end;
          $fmts{$name} = ( $params->{spaces} ? "a" : "A" ) . $len;
        } elsif ( $tmp_len =~ /^(\w)((?:\d+)?)$/ ) {
          my ($type, $repeat) = ($1, $2);
          my $len = $type =~ /[AaZ]/ && $repeat
                 || $type =~ /b/i && int((($repeat/16)-.01) + 1)
                 || $type =~ /h/i && int((($repeat/2)-.01) + 1)
                 || $type =~ /c/i && 1
                 || $type =~ /[sSnv]/ && 2
                 || $type =~ /[lLNV]/ && 4
                 || $type =~ /q/i && 8
                 || undef;
          unless ( $$params{no_validate} ) {
            if (defined $end) {
              confess "Bad length or end for field $name"
                unless $end == $start + $len - 1;
            }
          }
          $length += $len;
          $lengths{$name} = $len;
          push @lengths, $len;
          $nxt = $end + 1 if defined $end;
          $fmts{$name} = $tmp_len;
        } else {
          unless ( eval {
            my @foo = unpack($tmp_len, "junk"); 
            die "Too Many fields" unless @foo == 1;
            1;
          })
          {
            confess "Bad format $tmp_len for field $name";
          }
          $fmts{$name} = $tmp_len;
        }
    }
    return \@names, \@lengths, \%lengths, \%justify, $length, \%fmts;
}

# Check for duplicate field name, and if a duplicate,
# either die or return new autonumbered field name
sub _chk_dups {
    my ($name, $names, $fmts, $lengths,
        $justify, $dups, $dups_ok, $all_dups_ok) = @_;
    if (exists $$lengths{$name}) {
        confess "Duplicate field $name in format" 
            if !$dups_ok or !$all_dups_ok && !exists $$dups{$name};
    } else { return $name unless $$dups{$name} }
    # If this is the first duplicate found, fix the previous field
    unless ($$dups{$name}) {
        my $new_name = "${name}_".++$$dups{$name};
        confess "Can't autonumber field $name" if exists $$lengths{$new_name};
        for (@$names) { $_ = $new_name if $_ eq $name }
        $$lengths{$new_name} = $$lengths{$name};
        delete $$lengths{$name};
        $$fmts{$new_name} = $$fmts{$name};
        delete $$fmts{$name};
        if (exists $$justify{$name}) {
            $$justify{$new_name} = $$justify{$name};
            delete $$justify{$name};
        }
    }
    return "${name}_".++$$dups{$name};
}

sub _chk_start_end {
    my ($name, $prev, $start, $end) = @_;
    if (defined $start) {
        $start=~/^\d+$/ or confess "Start position not a number in field $name";
        $start == $prev or confess "Bad start position in field $name";
        defined $end    or confess "End position missing in field $name";
        $end =~ /^\d+$/ or confess "End position not a number in field $name";
        $end < $start  and confess "End position < start in field $name";
    }
}

sub _trim_info {
    my $parser = shift;
    my (@tfields, @tnames, @tpad);
    my $i = 0;
    for my $name (@{$parser->names}) {
        if (exists $parser->{JFIELDS}{$name}) {
            push @tfields, $i;
            push @tnames, $name;
            push @tpad, qr/^\Q$parser->{JFIELDS}{$name}\E+/;
        }
    } continue { $i++ }
    return \@tfields, \@tnames, \@tpad;
}

#=======================================================================
sub parse {
    my $parser = shift;
    my $data = $parser->{DATA};
    my $names = $parser->{NAMES};
    @{$data}{@$names} = unpack($parser->{UNPACK}, $_[0]);
    $parser->trim($data) if $parser->{TRIM};
    if (my $fh = $parser->{DEBUG}) {
     print $fh "# Debug parse\n";
     for my $name (@$names) {
         print $fh "[$name][$data->{$name}]\n";
     }
     print $fh "\n";
    }
    wantarray ? @$data{@$names} : $data;
}
#=======================================================================
sub parse_hash {
  return %{ scalar(shift->parse(@_)) };
}
sub parse_newref {
  return { shift->parse_hash(@_) };
}
#=======================================================================
sub pack {
    my $parser = shift;
    my $href = shift || $parser->{DATA};
    if ($parser->{JUST}) {
        while (my ($name, $chr) =  each %{$parser->{JFIELDS}}) {
            (my $field = $$href{$name}) =~ s/^\s+|\s+$//g;
            $field =~ s/^${chr}+// if $chr ne ' ';
            my $len = $parser->length($name);
            # Should we warn if we're truncating the field?
            $$href{$name} = substr(($chr x $len) . $field, -$len);
        }
    }
    # Print debug output after justifying fields
    if ($parser->{DEBUG}) {
     print "# Debug pack\n";
     for my $name (@{$parser->{NAMES}}) {
         print "[$name][$$href{$name}]\n";
     }
     print "\n";
    }
    CORE::pack $parser->{PACK}, @$href{@{$parser->{NAMES}}};
}
#=======================================================================
sub trim {
    my $self = shift;
    my $i;
    if (ref($_[0])) {
        my $href = shift;
        $href->{$_} =~ s/$self->{TPAD}[$i++]// for @{$self->{TNAMES}};
    } else {
        $_[$_] =~ s/$self->{TPAD}[$i++]// for @{$self->{TFIELDS}};
    }
}
#=======================================================================
sub names { shift->{NAMES} }
#=======================================================================
sub length {
    my $self = shift;
    @_ ? $self->{LENGTHS}{$_[0]} : $self->{LENGTH};
}
#=======================================================================
sub hash_to_obj {
    my $self = shift;
    my $href = shift;

    my $class_key = join "~=~", sort keys %$href;
    my $class = $Parse::FixedLength::HashAsObj::classes{$class_key} || do {
      no strict 'refs';
      my $name = $Parse::FixedLength::HashAsObj::classes{$class_key}
        = "Parse::FixedLength::HashAsObj::Href" .
        ++$Parse::FixedLength::HashAsObj::counter;
      @{"${name}::ISA"} = "Parse::FixedLength::HashAsObj";
      $name;
    };
    bless $href, $class;
}
#=======================================================================
sub dumper {
    my $parser = shift;
    my $pos_comment = shift;
    my $start = 1;
    my $end;
    my $delim = $parser->{DELIM};
    my $format = $pos_comment
       ? sub { sprintf("%s => '%s', # %s-%s", @_) }
       : $parser->{IS_HSH}
         ? sub { sprintf("%s => '%s${delim}%s${delim}%s',", @_) }
         : sub { join $delim, @_ };
    my $layout = '';
    my $jfields = $parser->{JFIELDS} || {};
    for my $name (@{$parser->names}) {
        my $len = $parser->length($name);
        $end = $start + $len - 1;
        my $just = exists $jfields->{$name}
          ? $jfields->{$name} eq ' ' ? 'R' : "R$jfields->{$name}"
          : '';
        $len .= $just;
        $layout .= $format->($name, $len, $start, $end) . "\n";
        $start = $end + 1;
    }
    $layout;
}
#=======================================================================
sub format_str { shift->{UNPACK} }
#=======================================================================
sub converter {
    Parse::FixedLength::Converter->new(@_);
}

package Parse::FixedLength::Converter;
use Carp;

#=======================================================================
sub new {
    # Do the OO cargo cult construction thing
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;

    my ($parser1, $parser2, $mappings, $defaults, $parms) = @_;
    $self->{UNPACKER} = $parser1;
    $self->{PACKER}   = $parser2;
    $mappings ||= {};
    confess 'Map arg not a hash or array ref'
        unless UNIVERSAL::isa($mappings, 'ARRAY')
            or UNIVERSAL::isa($mappings, 'HASH');
    $self->{MAP} = { reverse UNIVERSAL::isa($mappings, 'HASH')
        ?  %$mappings : @$mappings
    };
    $defaults ||= {};
    confess 'Defaults arg not a hash ref'
      unless UNIVERSAL::isa($defaults, 'HASH');
    my ($consts, $crefs) = ({}, {});
    while (my ($field, $default) = each %$defaults) {
        confess 'Default for field $field not a constant or code ref'
            unless ! ref $default or UNIVERSAL::isa($default, 'CODE');
        (ref $default ? $$crefs{$field} : $$consts{$field}) = $default;
    }
    $self->{CONSTANTS} = $consts;
    $self->{CODEREFS} = $crefs;
    $self->{NOPACK} = 1 if $parms->{no_pack};
    $self;
}
#=======================================================================
sub convert {
    my $converter = shift;
    my $data_in   = shift;
    my $no_pack   = @_ ? shift : $converter->{NOPACK};
    my $packer    = $converter->{PACKER};
    my $map_to    = $converter->{MAP};

    $data_in = $converter->{UNPACKER}->parse($data_in)
        unless UNIVERSAL::isa($data_in, 'HASH');
    my $names_out = $packer->names;

    # Map the data from input to output
    my $data_out = $packer->{DATA};
    @$data_out{@$names_out} = map {
        exists $map_to->{$_} ? $data_in->{$map_to->{$_}}
      : exists $data_in->{$_} ? $data_in->{$_} : ''
    } @$names_out;

    # Default/Convert the fields
    while (my ($name, $default) = each %{$converter->{CONSTANTS}}) {
        $data_out->{$name} = $default;
    }
    while (my ($name, $default) = each %{$converter->{CODEREFS}}) {
        $data_out->{$name} = eval { $default->($data_out->{$name}, $data_in) };
        confess "Failed to default field $name: $@" if $@;
    }
    $no_pack ? $data_out : $packer->pack($data_out);
}

package Parse::FixedLength::HashAsObj;

use vars qw($AUTOLOAD);
sub DESTROY { 1 }

sub AUTOLOAD : lvalue {
  no strict 'refs';
  my ( $class, $method ) = $AUTOLOAD =~ /^(.*)::(.+)$/
    or Carp::croak "Invalid call to $AUTOLOAD";
  Carp::croak "Can't locate object method $method via package $class"
    unless exists $_[0]->{$method};
  *$AUTOLOAD = sub : lvalue {
    my $self = shift;
    if (@_) {
      $self->{$method} = shift;
      return $self;
    }
    $self->{$method};
  };
  goto &$AUTOLOAD;
  # To placate the compiler you must appear
  # to return an lvalue-able value
  $Parse::FixedLength::HashAsObj::foo;
}
1;
__END__

=head1 NAME

Parse::FixedLength - parse an ascii string containing fixed length fields into component parts

=head1 SYNOPSIS

    use Parse::FixedLength qw(subclassed parsers);
    
    $parser = Parse::FixedLength->new(\@format);
    $parser = Parse::FixedLength->new(\@format, \%parameters);
    $parser = Parse::FixedLength->new($format);
    $parser = Parse::FixedLength->new($format, \%parameters);

    $hash_ref = $parser->parse($data);
    $data = $parser->pack($hash_ref);

    $converter = $parser1->converter($parser2);
    $converter = $parser1->converter($parser2, \%mappings);
    $converter = $parser1->converter($parser2, \@mappings);
    $converter = $parser1->converter($parser2, \%mappings, \%defaults);
    $converter = $parser1->converter($parser2, \@maps, \%dflts, \%parms);

    $data_out = $converter->convert($data_in);

=cut

=head1 DESCRIPTION

The C<Parse::FixedLength> module facilitates the process of breaking
a string into its fixed-length components. Sure, it's a glorified
(and in some ways more limited) substitute for the perl functions pack and
unpack, but it's my belief that this module helps in the maintainability
of working with fixed length formats as the number of fields in a format grows.

=cut

=head1 PARSING METHODS

=head2 new() 

 $parser = Parse::FixedLength->new(\@format)
 $parser = Parse::FixedLength->new(\@format, \%parameters)
 $parser = Parse::FixedLength->new($format)
 $parser = Parse::FixedLength->new($format, \%parameters)

If the format argument is a string, then new will attempt
to return the result of calling the new method for
"Parse::FixedLength::$format". You can include the '$format' in
the import list of the 'use Parse::FixedLength' statement if
you want to require the format at compile time (See EXAMPLES).

You can use ':all' as an argument in the import list, e.g.,
'use Parse::Length qw(:all)', to require all available
Parse::FixedLength::* modules, but obviously you can't use ':all'
as a format argument in new().

Otherwise the format must be an array reference of field names and
lengths as either alternating elements, or delimited args in the
same field, e.g.:

    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        address    => 20,
    ]);

    or:

    my $parser = Parse::FixedLength->new([qw(
        first_name:10
        last_name:10
        address:20
    )]);

If the first format is chosen, then no delimiter characters may
appear in the field names (see delim option below).

To right justify a field (during the 'pack' method), an "R" may
be appended to the length of the field followed by (optionally)
the character to pad the string with (if no character follows the
"R", then a space is assumed). This is somewhat inefficient,
so its only recommended if actually necessary to preserve the format
during operations such as math or converting format lengths. If its
not needed but you'd like to specify it anyway for documentation
purposes, you can use the no_justify option below. Also, it does change
the data in the hash ref argument.

New (and barely tested): The length of the field may also be any valid
format string for the perl functions pack/unpack which would return
a single element.  E.g., this is valid:

    my $parser = Parse::FixedLength->new([qw(
        first_name:10:1:10
        last_name:10:11:20
        address:20:21:40
        flags:B16:41:42
    )]);

But this is not valid since 'flags' would return 2 elements:

    my $parser = Parse::FixedLength->new([qw(
        first_name:10:1:10
        last_name:10:11:20
        address:20:21:40
        flags:C2:41:42
    )]);

If a format without a known fixed length is used, then the
length method, and start and end positions in the format
should not be used.

The optional second argument to new is a hash ref which may contain
any of the following keys:

=over 4

=item delim

The delimiter used to separate the name and length in the
format array. If another delimiter follows the length then
the next two fields are assumed to be start and end position,
and after that any 'extra' fields are ignored.  The package variable
DELIM may also be used.
(default: ":")

=item href

A hash reference to parse the data into. Also, if no argument is passed
to the pack method, the default hash reference used to pack the
data into a fixed length string.

=item no_bless

Do not bless the hash ref returned from the parse method into
a Hash-As-Object package.
(default: false)

=item all_lengths

This option ignores any lengths supplied in the format
argument (or allows having no length args in the format), and
sets the lengths for all the fields to this value. As well as
the obvious case where all formats are the same length, this can
help facilitate converting from a non-fixed length format (where
you just have field names) to a fixed-length format.
(default: false)

=item autonum

This option controls the behavior of new() when duplicate
field names are found. By default a fatal error will be
generated if duplicate field names are found. If you have,
e.g., some unused filler fields, then as the value to this
option, you can either supply an arrayref containing valid
duplicate names or a simple true value to accept all duplicate
values. If there is more than one duplicate field, then when
parsed, they will be renamed '<name>_1', '<name>_2', etc.
(default: false)

=item spaces

If true, preserve trailing spaces during parse.
(default: false)

=item no_justify

If true, ignore the "R" format option during pack.
(default: false)

=item no_validate

By default, if two fields exist after the length
argument in the format (delimited by whatever delimiter is
set), then they are assumed to be the start and end position
(starting at 1), of the field, and these fields are validated
to be correct, and a fatal error will be generated if they
are not correct.  If this option is true, then the start and
end are not validated.
(default: false)

=item trim

If true, trim leading pad characters from fields during parse.
(default: false)

=item debug

If true, print field names and values during parsing and
packing (as a quick format validation check). The package
variable DEBUG may also be used. If a non-reference
argument is given, output is sent to STDOUT, otherwise we
assume we have a filehandle open for writing.
(default: false)

=back

=head2 parse() 

 $hash_ref = $parser->parse($string)
 @ary      = $parser->parse($string)

This method takes a string and returns a hash reference of
field names and values if called in scalar context, or just a list of the
values if called in list context. The hash reference returned is
an object, so you can either get/set values the normal way:

    $href->{key} = "value";
    print "$href->{key}\n";

or you can use methods:

    $href->key = "value";
    print $href->key,"\n";

For efficiency, the same hash reference is returned on each parse.
If this is not acceptable, look into L</parse_newref> or L</parse_hash>.
See L<CAVEATS>.

=head2 parse_hash() 

 %hash = $parser->parse_hash($string)

Same as parse, but returns a hash array instead of a hash reference.

=head2 parse_newref() 

 $hash_ref = $parser->parse_newref($string)

Same as parse, but returns a different hash reference on every call,
and the reference returned is not an object, just a plain old
hashref.

=head2 pack()

 $data = $parser->pack(\%data_to_pack);

This method takes a hash reference of field names and values and
returns a fixed length format output string.

If no argument is passed, then the hash reference used in the
href option of the constructor is used.

=head2 hash_to_obj()

 Parse::FixedLength->hash_to_obj($href);
 $parser->hash_to_obj($href);

This turns a hash reference into an object where the keys of the
hash can be used as methods for accessing or setting the values
of the hash. This turns the hash into a semi-secure hash which is
a sort of combination of L<Hash::AsObject|Hash::AsObject> and
L<Tie::SecureHash|Tie::SecureHash> in that no new keys will be
added to the hash if only methods are used to access the hash. Hashes
with the same set of keys are blessed into the same package, so adding
keys to one hash may affect the methods allowed on another hash.

=head2 trim()

 $parser->trim(@data);
 $parser->trim(\%data);

This method trims leading pad characters from the data. It is the
method implicitly called during the parse method when the 'trim' option
is set in new(). The data passed is modified, so there is no return value.

=head2 names()

 $ary_ref = $parser->names;

Return an ordered arrayref of the field names.

=head2 format_str()

 $fmt_str = $parser->format_str;

Return the format string used for unpacking.

=head2 length()

 $tot_length   = $parser->length;
 $field_length = $parser->length($name);

Returns the total length of all the fields, or of just one field name.
E.g.:

 # If there are no line feeds
 while (read FH, $data, $parser->length) {
  $parser->parse($data);
  ...
 }

=head2 dumper()

 $parser->dumper($pos_as_comments);

Returns the parser's format layout information in a format suitable
for cutting and pasting into the format array argument of a
Parse::FixedFormat->new() call, and includes the start and end positions
of all the fields (starting with position 1). If a true argument is supplied
then it will include the start and ending positions as comments. E.g.:

 # Assume the parser is from the ones defined in the new() example:
 print $parser->dumper(1);

 produces for first example:
 first_name => 10, # 1-10
 last_name => 10, # 11-20
 address => 20, # 21-40 

 or for the second example:
 print $parser->dumper;

 first_name:10:1:10
 last_name:10:11:20
 address:20:21:40

=head2 converter()

 $converter = $parser1->converter($parser2, \@maps, \%dflts, \%parms);

Returns a format converting object. $parser1 is the parsing object
to convert from, $parser2 is the parsing object to convert to.

By default, common field names will be mapped from one format to the other.
Fields with different names can be mapped from the first format to the
other (or you can override the default) using the second argument.
The keys are the source field names and the corresponding values are
the target field names. This argument can be a hash ref or an array
ref since you may want to map one source field to more than one
target field.

Defaults for any field in the target format can be supplied
using the third argument, where the keys are the field names of
the target format, and the value can be a scalar constant, or a
subroutine reference where the first argument is simply the mapped
value (or the empty string if there was no mapping), and the
second argument is the entire hash reference that results from parsing
the data with the 'from' parser object. E.g. if you were mapping
from a separate 'zip' and 'plus_4' field to a 'zip_plus_4' field,
you could map 'zip' to 'zip_plus_4' and then supply as one of the
key/value pairs in the 'defaults' hash ref the following:

 zip_plus_4 => sub { shift() . $_[0]{plus_4} }

The fourth argument is an optional hash ref may which may
contain the following:

=over 4

=item no_pack

If true, the convert() method will return a hash reference
instead of packing the data into an ascii string
(Default: false).

=back

=head2 convert()

 $data_out = $converter->convert($data_in);
 $data_out = $converter->convert($data_in, $no_pack);
 $data_out = $converter->convert(\%hash);
 $data_out = $converter->convert(\%hash, $no_pack);

Converts a string or a hash reference from one fixed length format to another.
If a second argument is supplied, it will override the converter's no_pack option setting.


=head1 EXAMPLES

    use Parse::FixedLength;

    # Include start and end position for extra check
    # of format integrity
    my $parser = Parse::FixedLength->new([
        first_name => '10:1:10',
        last_name  => '10:11:20',
        widgets_this_month => '5R0:21:25',
    ]);

    # Do a simple name casing of names
    # and print widgets projected for the year for each person
    while (<DATA>) {
        warn "No record terminator found!\n" unless chomp;
        warn "Short Record!\n" unless $parser->length == length;
        my $data = $parser->parse($_);
        # See Lingua::EN::NameCase for a real attempt at name casing
        s/(\w+)/\u\L$1/g for @$data{qw(first_name last_name)};
        $data->{widgets_this_month} *= 12;
        print $parser->pack($data), "\n";
    }
    __DATA__
    BOB       JONES     00024
    JOHN      SMITH     00005
    JANE      DOE       00007

    Another way if we're converting formats:

    my $parser1 = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        widgets_this_month => '5R0',
    ]);

    my $parser2 = Parse::FixedLength->new([qw(
        seq_id:10
        first_name:10
        last_name:10
        country:3
        widgets_this_year:10R0
    )]);

    my $converter = $parser1->converter($parser2, {
        widgets_this_month => "widgets_this_year",
    },{
        seq_id => do { my $cnt = '0' x $parser2->length('seq_id');
                       sub { ++$cnt };
                     },
        widgets_this_year => sub { 12 * shift },
        country => 'USA',
    });
    

    while (<DATA>) {
        warn "No record terminator found!\n" unless chomp;
        warn "Short Record!\n" unless $parser1->length == length;
        print $converter->convert($_), "\n";
    }

=head2 Subclassing Example

    # Must be installed as Parse/FixedLength/DrugCo100.pm
    # somewhere in @INC path.
    package Parse::FixedLength::DrugCo100;

    use Parse::FixedLength;
    our @ISA = qw(Parse::FixedLength);

    sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        $flags = shift || {};
        die "Options arg not a hash ref"
            unless UNIVERSAL::isa($flags,'HASH');
        $$flags{autonum} = ['filler'];
        bless $class->SUPER::new([qw(
            stuff:40
            filler:10
            more_stuff:40
            filler:10
        )], $flags), $class;
    }

    Then in main script:

    # Import list on use statement is optional, but
    # will cause require at compile time rather than run time.
    use Parse::FixedLength qw(DrugCo100);
    my $parser = Parse::FixedLength->new('DrugCo100'); 
    etc...

    # Or of course you could just:
    use Parse::FixedLength::DrugCo100;
    my $parser = Parse::FixedLength::Drugco100->new;

=head1 CAVEATS

Mentioned in the documentation for L</parse>, repeated here:

For efficiency, a parser object will return the same hash reference
on every call to parse. Therefore, any code such as this
which tries to save every record will not work:

    while (<>) {
        my $href = $parser->parse($_);
        push @array, $href; # Refers to same hash every time
    }

and should be changed to this:

    while (<>) {
        my $href = $parser->parse_newref($_);
        push @array, $href;
    }

or this:

    while (<>) {
        my $href = $parser->parse($_);
        push @array, { %$href };
    }


=head1 AUTHOR

 Douglas Wilson <dougw@cpan.org>
 original by Terrence Brannon <tbone@cpan.org>

=head1 COPYRIGHT

 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 SEE ALSO

Other glorified substitutes for pack/unpack:
L<Text::FixedLength|Text::FixedLength>, L<Data::FixedFormat|Data::FixedFormat>,
L<AnyData::Format::Fixed|AnyData::Format::Fixed> (although
the AnyData module is part of a larger collection of modules which
facilitates converting data between many different kinds of formats, and
using SQL to query those data sources via L<DBD::AnyData|DBD::AnyData>).

=cut
