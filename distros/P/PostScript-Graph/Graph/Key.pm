package PostScript::Graph::Key;
our $VERSION = 1.03;
use strict;
use warnings;
use Exporter;
use Carp;
use PostScript::File	     1.00 qw(str);
use PostScript::Graph::Paper 1.00;

our @ISA = qw(Exporter);

=head1 NAME

PostScript::Graph::Key - a Key area for PostScript::Graph::Paper

=head1 SYNOPSIS

    use PostScript::File;
    use PostScript::Graph::Key;
    use PostScript::Graph::Paper;
    
=head2 Typical

A Key panel is drawn to the right of its associated graph.  The area needed for the Key panel must be calculated
before the graph Paper can be drawn in the remaining space.

    my $ps = new PostScript::File;
    my @bbox = $psf->get_page_bounding_box();

    # Calculate variables from the graph data
    # planned layout and available space ...
    
    my $gk = new PostScript::Graph::Key(
		num_items   => ... ,
		max_height  => ... ,
		text_width  => ... ,
		icon_width  => ... ,
		icon_height => ... ,
	    );

    # Need to pass this to GraphPaper
    my $width = $pgk->width();

    my $gp = new PostScript::Graph::Paper(
		file => $ps,
		chart => {
		    key_width => $width,
		},
	    );

    # Now we can link the two
    $gk->build_key( $gp );

    foreach $line (@lines) {
	... draw line on graph_paper ...

	$gk->add_key_item( $title, <<END );
	    ... postscript code 
	    ... drawing icon
    END
    }

=head2 All options

    my $gp = new PostScript::Graph::Key(
	file => $ps_file,
	graph_paper => $ps_gpaper,
	max_height => 500,
	num_items => 5,
	background => 0.9,
	outline_color => [0.5, 0.5, 0.2],
	outline_wdith => 0.8,
	spacing => 4,
	horz_spacing => 4,
	vert_spacing => 6,
	icon_height => 12,
	icon_width => 40,
	text_width => 72,
	text_font => {
	    size => 10,
	    color => 0,
	    font => 'Courier',
	},
	title => 'My Key',
	title_font => {
	    color => [1, 0, 0],
	    font => 'Times-Bold',
	    size => 14,
	},
    };

=head1 DESCRIPTION

This module is designed as a supporting part of the PostScript::Graph suite.  For top level modules that output
something useful, see

    PostScript::Graph::Bar
    PostScript::Graph::Stock
    PostScript::Graph::XY

A companion object to PostScript::Graph::Paper, this is used by any module that requies a Key for a graph.  The
size and shape is automatically adjusted to accomodate the number of items in the space available, adding more
columns if there is not enough vertical space.  The textual description now wraps onto multiple lines if needed.

The opportunity is provided to draw an icon with each key item using the same code and style as is used on the
graph.  This is accomplished in distinct phases.  

=over 4

=item *

The total space available is typically obtained from PostScript::File, but must be known so that
PostScript::Graph::Key and PostScript::Graph::Paper can divide it between them.

=item *

All the graph lines must exist before the graph is drawn.  PostScript::Graph::Paper needs to calculate the axes
and suggest the height available for the Key which will be placed to the right of the graph.

=item *

The PostScript::Graph::Key constructor calculates the outer box dimensions from the items required and the space
available.  In particular the number of text rows per item must be worked out and how many columns will be needed.

=item *

The key width can then be passed to the PostScript::Graph::Paper constructor, which works out the space available
for the graph and usually draws the background grid.

=item *

B<build_key> can then be called to draw the outer box and heading next to the grid.

=item *

For each graph line, the line can be drawn on the paper and its icons drawn in the key box at the same time, using
the same PostScript::Graph::Style settings.

=back


=head1 CONSTRUCTOR

=cut

sub new {
    my $class = shift;
    my $opt = {};
    if (@_ == 1) { 
	$opt = $_[0]; 
    } elsif (@_ == 2 and $_[0]+0 > 0) {
	($opt->{max_height}, $opt->{num_items}) = @_; 
    } else { 
	%$opt = @_; 
    }
   
    my $o = {};
    bless( $o, $class );
    
    $o->{gp}       = defined($opt->{graph_paper})        ? $opt->{graph_paper}         : undef;
    my $ps         = defined($o->{gp})                   ? $o->{gp}->file()            : undef;
    $o->{ps}       = defined($opt->{file})               ? $opt->{file}                : $ps;

    $o->{title}    = defined($opt->{title})              ? $opt->{title}               : "Key";
    $o->{hcolor}   = defined($opt->{title_font}{color})  ? $opt->{title_font}{color}   : 0;
    $o->{hfont}    = defined($opt->{title_font}{font})   ? $opt->{title_font}{font}    : 'Helvetica-Bold';
    $o->{hsize}    = defined($opt->{title_font}{size})   ? $opt->{title_font}{size}    : 12;
    $o->{tcolor}   = defined($opt->{text_font}{color})   ? $opt->{text_font}{color}    : 0;
    $o->{tfont}    = defined($opt->{text_font}{font})    ? $opt->{text_font}{font}     : 'Helvetica';
    $o->{tsize}    = defined($opt->{text_font}{size})    ? $opt->{text_font}{size}     : 10;
    $o->{ratio}    = defined($opt->{glyph_ratio})        ? $opt->{glyph_ratio}         : 0.44;
    $o->{twidth}   = defined($opt->{text_width})         ? $opt->{text_width}          : $o->{tsize} * 4;
    $o->{fcolor}   = defined($opt->{background})         ? $opt->{background}          : 1;
    $o->{ocolor}   = defined($opt->{outline_color})      ? $opt->{outline_color}       : 0;
    $o->{owidth}   = defined($opt->{outline_width})      ? $opt->{outline_width}       : 0.75;
    
    $o->{items}	   = $opt->{item_labels};			# used by wrapped_items()
    $o->{wrapchrs} = $o->{twidth}/($o->{tsize}*$o->{ratio});	# used by wrapped_items()
    if (defined $o->{items}) {
	$o->{nlines} = $o->wrapped_items;
    } else {
	croak "Option 'num_items' must be given\nStopped" unless $opt->{num_items};
	$o->{nlines} = [ (1) x $opt->{num_items} ];
    }
    
    $o->{spc}      = defined($opt->{spacing})            ? $opt->{spacing}             : 4;
    $o->{vspc}     = defined($opt->{vert_spacing})       ? $opt->{vert_spacing}        : $o->{spc};
    $o->{hspc}     = defined($opt->{horz_spacing})       ? $opt->{horz_spacing}        : $o->{spc} * 2;
    $o->{dxicon}   = defined($opt->{icon_width})         ? $opt->{icon_width}          : $o->{tsize};
    $o->{dyicon}   = defined($opt->{icon_height})        ? $opt->{icon_height}         : $o->{tsize};
    
    $o->{dx}       = $o->{hspc} + $o->{dxicon} + $o->{hspc} + $o->{twidth} + $o->{hspc};
    $o->{dyicon}   = ($o->{dyicon} > $o->{tsize} ? $o->{dyicon} : $o->{tsize});	       # dyicon always >= tsize
    my $isize      = $o->{dyicon} + 2 * $o->{vspc};

    croak "Option 'max_height' must be given\nStopped" unless defined $opt->{max_height};
    $o->{height}   = $opt->{max_height};
    $o->{tmargin}  = $o->{hsize} + 3 * $o->{vspc};
    my $margins    = $o->{tmargin} + 2 * $o->{vspc};
    my $height     = $o->{height} - $margins;
    $height        = 1 unless $height > 0;
    
    # distribute items amongst columns
    my $sofar  = 0;
    my $column = 0;
    my $max    = 0;
    my (@cols, @rowp, @rowh);
    for (my $i = 0; $i <= $#{$o->{nlines}}; $i++) {
	$rowp[$i] = $sofar;
	my $itemh = 2* $o->{vspc} + $o->{nlines}[$i] * ($o->{tsize} + $o->{vspc});
	#warn "$i nlines=",$o->{nlines}[$i],", itemh=$itemh, rowp=",$rowp[$i],"\n";
	$sofar   += $itemh;
	if ($sofar >= $height) {
	    $sofar -= $itemh;
	    $max    = $sofar if $sofar > $max;
	    $column++;
	    $rowp[$i] = 0;
	    $sofar    = $itemh;
	}
	$cols[$i] = $column;
	if ($isize > $itemh) {
	    $rowh[$i] = $isize;
	    $sofar += ($isize - $itemh);
	} else {
	    $rowh[$i] = $itemh;
	}
	$max = $sofar if $sofar > $max;
	#warn "$i column=$column, diff=$diff ($isize - $itemh), sofar=$sofar, max=$max\n"
    }
	
    #warn "max=$max, column=$column\n";
    $o->{height}   = $margins + $max;
    $o->{start}    = $o->{height} - $o->{tmargin} - 4 * $o->{vspc};
    $o->{width}    = $o->{hspc} + ($column+1) * $o->{dx};

    # for add_key_item()
    $o->{cols}     = \@cols;	# the column number for each item
    $o->{rowp}     = \@rowp;	# offset from top of column to top of item
    $o->{current}  = 0;		# item to be shown
    
    return $o;
}

=head2 new( [options] )

C<options> should be either a list of hash keys and values or a hash reference.  Unlike other objects in this
series, a couple of these (C<max_height> and C<num_items>) are required.  Another difference is that all options
occur within a flat space - there are no sub-groups.  This is because it is expected that this module will only be
used as part of another Chart object, with these options passed as a group through that constructor.

All values are in PostScript native units (1/72 inch).

If C<num_items> is an integer, the textual description will have one line per item.  Where long descriptions are
needed, C<item_labels> can be given instead.  It should refer to a list of the strings to be placed next to each
key icon.  The constructor calculates the number of rows needed when this text is wrapped within C<text_width>.
The text is only actually wrapped when B<add_key_item> is called.

=head3 background 

Background colour for the key rectangle.  (Default: 1)

=head3 file

If C<graph_paper> is not given, this probably should be.  It is the PostScript::File object that holds the graph
being constructed.  It is possible to specify this later, when calling B<add_key_item>.  (No default)

=head3 glyph_ratio

A kludge provided to fine-tune how well the text labels fit into the box.  It is not possible to get the actual
width of proportional font strings from PostScript, so this gives the opportunity to guess an 'average width' for
particular fonts.  (Default: 0.5)

=head3 graph_paper

If given, this should be a PostScript::Graph::Paper object.  A GraphKey needs to know which GraphPaper
has allocated space for it.  But the GraphPaper need the GraphKey to have already worked out how much space it
needs.  The best solution is to create the GraphKey before the GraphPaper, then pass the latter to B<build_chart>.
(No default)

=head3 horizontal_spacing

The gaps between edges, icon and text.  (Defaults to C<spacing>)

=head3 icon_height

Vertical space for each icon.  This will never be smaller than the height of the text.  (Defaults to C<text_size>)

=head3 icon_width

Amount of horizontal space to allow for the icon to the left of each label.  (Defaults to C<text_size>)

=head3 item_labels

As an alternative to specifying the number of items (which must be single lines of text), this takes an array ref
pointing to a list of all the key labels that will later be added.  The same wrapping algorithm is applied to
both.  The box dimensions are calculated from these, but the actual text printed should be passed seperately to
B<add_key_item>.

=head3 max_height

The vertical space available for the key rectangle.  GraphKey tries to fit as many items as possible within this
before adding another column.  Required - there is no default.

=head3 num_items

The number of items that will be placed in the key.  Required unless C<item_labels> is given.

=head3 outline_color

Colour of the box's outline.  (Default: 0)

=head3 outline_width

Width of the box's outline.  (Default: 0.75)

=head3 spacing

A larger value gives a less crowded feel, reduce it if you are short of space.  Think printing leading.  (Default: 4)

=head3 text_color

Colour of the text used in the body of the key.  (Default: 0)

=head3 text_font

Font used for the key body text.  (Default: "Helvetica")

=head3 text_size

Size of the font used for the key body text.  (Default: 10)

=head3 text_width

Amount of room allowed for the text label on each key item.  (Defaults to four times the font size)

=head3 title

The heading at the top of the key rectangle.  (Default: "Key")

=head3 title_color

Colour of the key heading.  (Default: 0)

=head3 title_font

The font used for the heading.  (Default: "Helvetica-Bold")

=head3 title_size

Size of the font used for the heading.  (Default: 12)

=head3 vertical_spacing

The gap between key items.  (Defaults to C<spacing>)

=head1 OBJECT METHODS

=cut

sub width { 
    return shift()->{width}; 
}

=head2 width()

Return the width required for the key rectangle.

=cut

sub height { 
    return shift()->{height}; 
}

=head2 height()

Return the height required for the key rectangle.

=cut

sub build_key {
    my ($o, $gp) = @_;
    if (defined $gp) {
	$o->{gp} = $gp;
	$o->{ps} = $gp->file();
    }
    die "No PostScript::Graph::Paper object\nStopped" unless (ref($o->{gp}) eq "PostScript::Graph::Paper");

    my ($kx0, $ky0, $kx1, $ky1) = $o->{gp}->key_area();
    my $offset = ($ky1 - $ky0 - $o->{height})/2;
    $ky0 += $offset;
    $ky1 = $ky0 + $o->{height};
    my $textc = str($o->{tcolor});
    my $headc = str($o->{hcolor});
    my $outlinec = str($o->{ocolor});
    my $fillc = str($o->{fcolor});
    
    $o->{ps}->add_to_page( <<END_CODE );
	graphkeydict begin
	    /kx0 $kx0 def 
	    /ky0 $ky0 def 
	    /kx1 $kx1 def 
	    /ky1 $ky1 def
	    /kvspc $o->{vspc} def 
	    /khspc $o->{hspc} def
	    /kdxicon $o->{dxicon} def
	    /kdyicon $o->{dyicon} def
	    /kdxtext $o->{twidth} def
	    /kdytext $o->{tsize} def
	    /kfont /$o->{tfont} def
	    /ksize $o->{tsize} def
	    /kcol $textc def
	    ($o->{title}) /$o->{hfont} $o->{hsize} $headc $o->{owidth} $outlinec $fillc keybox
	end
END_CODE

    PostScript::Graph::Key->ps_functions($o->{ps});
}

=head2 build_key( [graph_paper] )

This is where the position of the key area is fixed and the outline and heading are drawn.  It must be called
before B<add_key_item>.

=cut

sub add_key_item {
    my ($o, $label, $code, $ps) = @_;
    #warn "add_key_item($label)\n";
    $label   = ""  unless (defined $label);
    $code    = ""  unless (defined $code);
    $o->{ps} = $ps if     (defined $ps);
    die "No PostScript::File object to write to\nStopped" unless (ref($o->{ps}) eq "PostScript::File");
    
    my @lines = $o->{items} ? $o->split_lines(ucfirst $label) : ucfirst($label);
    my $tsize = $o->{tsize} + $o->{vspc};
    
    my $n   = $o->{current};
    my $col = $o->{cols}[$n] || 0;
    my $row = $o->{rowp}[$n] || 0;
    my $kdx = $col * $o->{dx};
    my $kdy = $o->{start} - $row;
    #
    # TODO Centre the icon box within the text entry.
    # $o->{rowh} holds the necessary height, but it needs putting into PostScript
    #
    
    # The gstyledict kludge involving tppdy/tppdx is to ensure the point is shown centrally in the icon.
    # This may not be what is always wanted, but was put in to accomodate arrows (without lines)
    $o->{ps}->add_to_page( <<END_ITEM );
	graphkeydict begin
	    /kdx $kdx def
	    /kdy $kdy def
	    newpath
	    movetoicon
	    gstyledict begin
		/tppdy ppdy def /ppdy 0 def
		/tppdx ppdx def /ppdx 0 def
		$code
		stroke
		/ppdy tppdy def
		/ppdx tppdx def
	    end
	    movetotext
END_ITEM
    foreach my $line (@lines) {
	$line =~ s/[(]/\\\(/g;
	$line =~ s/[)]/\\\)/g;
	$o->{ps}->add_to_page("($line) show $tsize movedown\n");
    }
    $o->{current}++;
    $o->{ps}->add_to_page("end\n");
}

=head2 add_key_item( label, code [, psfile] )

=over 8

=item label

The text for this key item

=item code

Postscript code which draws the icon.

=item psfile

The PostScript::File object the code will be written to.  If it was not given to B<new> as either C<file> or
C<graph_paper>, it must be given here.

=back

A number of postscript variables are provided to help with the drawing.  See <L/POSTSCRIPT CODE> for the full list.

    kix0    left edge of icon area
    kiy0    bottom edge
    kix1    right edge
    kiy1    top edge

Your code should use its own dictionary and can refer to dictionaries you have begun but not yet ended at this
point.  For example, here is the code used by PostScript::Graph::XY.  It calculates the mid point of a diagonal line
and draws it using the same functions used for the main chart.  C<line_outer> etc. are provided by
PostScript::Graph::Style to change style settings, C<draw1point> just expects 'x y' and C<drawxyline> expects an
array of coordinates followed by the greatest index allowed.

    
	$graphkey->add_key_item( $line->{ytitle}, 
				 <<END_KEY_ITEM );
	    2 dict begin
		/kpx kix0 kix1 add 2 div def
		/kpy kiy0 kiy1 add 2 div def
		point_outer 
		kpx kpy draw1point
		[ kix0 kiy0 kix1 kiy1 ] 3  
		2 copy 
		line_outer drawxyline 
		line_inner drawxyline
		point_inner 
		kpx kpy draw1point
	    end
    END_KEY_ITEM

=cut

sub wrapped_items {
    my $o = shift;
    my @items = @_ ? @_ : @{$o->{items}};
    my @split;
    my $nchars = $o->{twidth}/($o->{tsize}*$o->{ratio});
    foreach my $text (@items) {
	push @split, scalar $o->split_lines($text, $nchars);
    }
    return \@split;
}
# Fit labels in $o->{items} array so they fit within $o->{twidth}
# Returning number of lines required in total.


sub split_lines {
    my ($o, $text, $nchars) = @_;
    $nchars = $o->{wrapchrs} unless defined $nchars;
    my @split_text;
    while ($text) {
	my ($left, $right);
	if (length $text <= $nchars) {
	    $left = $text;
	    $right = '';
	} else {
	    $left = substr $text, 0, $nchars;
	    $right = substr $text, $nchars;
	    $left =~ s/\s+(\S*)$//;
	    $right = $1 . $right if $1;
	}
	push @split_text, $left;
	$text = $right;
    }
    return @split_text;
}

sub sum {
    my $total = 0;
    foreach my $item (@_) {
	$total += $item;
    }
    return $total;
}

sub ps_functions {
    my ($class, $ps) = @_;
    my $name = "GraphKey";
    $ps->add_function( $name, <<END_FUNCTIONS ) unless ($ps->has_function($name));
	/graphkeydict 20 dict def
	graphkeydict begin
	    % _ title tfont tsize tcol boxw boxc fillc => _
	    /keybox {
		gpaperdict begin
		graphkeydict begin
		    newpath
		    kx0 ky0 moveto
		    kx1 ky0 lineto
		    kx1 ky1 lineto
		    kx0 ky1 lineto
		    closepath
		    gsave gpapercolor fill grestore
		    gpapercolor 
		    setlinewidth
		    [ ] 0 setdash
		    stroke
		    /tcol exch def
		    /tsize exch def
		    /tfont exch def
		    tfont tsize tcol gpaperfont
		    kx0 kx1 add 2 div
		    ky1 tsize 1.2 mul sub
		    centered
		end end
	    } bind def
	
	    % _ => _
	    /movetoicon {
		graphkeydict begin
		    /kix0 kx0 kdx add khspc add def
		    /kiy0 ky0 kdy add def
		    /kix1 kix0 kdxicon add def
		    /kiy1 kiy0 kdyicon add def
		    kix0 kiy0 moveto
		end
	    } bind def
		
	    % _ => _
	    /movetotext {
		graphkeydict begin
		    gpaperdict begin
			kfont ksize kcol gpaperfont
		    end    
		    /ktx0 kx0 kdx add khspc add kdxicon add khspc add def
		    /kty0 ky0 kdy add def
		    /ktx1 ktx0 kdxtext add def
		    /kty1 kty0 kdyicon add def
		    ktx0 kty0 kty1 add 2 div ksize 2 div sub kvspc 2 div add moveto
		end
	    } bind def

	    % tsize => _
	    /movedown {
		graphkeydict begin
		    /kty0 1 index kty0 exch sub def
		    /kty0 exch kty0 exch sub def
		    ktx0 kty0 kty1 add 2 div ksize 2 div sub kvspc 2 div add moveto
		end
	    } bind def
	end
END_FUNCTIONS
}

=head3 ps_functions( ps )

Normally, this is called in B<build_key>, but is provided as a class function so the dictionary may be still
available even when a Key object is not required.

=cut

=head1 POSTSCRIPT CODE

None of the postscript functions defined in this module would have application outside it.  However, the following
variables are defined within the C<graphkeydict> dictionary and may be of some use.

    kix0	left edge of icon area
    kiy0	bottom edge
    kix1	right edge
    kiy1	top edge
    kvspc	vertical spacing
    khspc	horizontal spacing
    kdxicon	width of icon area
    kdyicon	height of icon area
    kdxtext	width of text area
    kdytext	height of text area
    kfont	font used for text
    ksize	font size used
    kcol	colour of font used

=cut

=head1 BUGS

Too much space is allocated to wrapped text if accompanied by a large icon.

=head1 AUTHOR

Chris Willmot, chris@willmot.org.uk

=head1 SEE ALSO

L<PostScript::File>, L<PostScript::Graph::Style> and L<PostScript::Graph::Paper> for the other modules in this suite.

L<PostScript::Graph::Bar>, L<PostScript::Graph::XY> and L<Finance::Shares::Chart> for modules that use this one.

=cut


1;
