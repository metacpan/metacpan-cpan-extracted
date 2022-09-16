package PDF::Builder::Page;

use base 'PDF::Builder::Basic::PDF::Pages';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use Carp;
use POSIX qw(floor);
use Scalar::Util qw(looks_like_number weaken);

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Content;
use PDF::Builder::Content::Text;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Page - Methods to interact with individual pages

=head1 SYNOPSIS

    my $pdf = PDF::Builder->new();

    # Add a page to a new or existing PDF
    my $page = $pdf->page();

    # Set the physical (media) page size
    # Set prepress page boundaries, a convenience function for those times when
    # it is not necessary to set other prepress (print-related) page boundaries
    $page->size('letter'); # by common size name
   #$page->size([0, 0, 612, 792]); # by points LLx,LLy, URx,URy

    # alternately, can set (or get) prepress page boundaries
    $page->boundaries('media' => '12x18', 'trim' => 0.5 * 72);

    # Add an image
    my $image = $pdf->image('/path/to/file.jpg');
    $page->object($image, $x,$y, $w,$h);

    # Create a content object for text
    my $text = $page->text();

    # Create a content object for drawing shapes
    my $canvas = $page->graphics();  # or gfx()

    # Now to draw graphics (using $canvas object) and text (using $text object).
    # NOTE that everything in the graphics (canvas) object will be laid down on
    #   the page BEFORE anything in the text object is laid down. That is,
    #   text will cover graphics, but not vice-versa. This is simply due to
    #   the order in which the objects were defined.
    
=head1 METHODS

=over

=item $page = PDF::Builder::Page->new($pdf, $parent, $index)

Returns a page object (called from $pdf->page()).

=cut

sub new {
    my ($class, $pdf, $parent, $index) = @_;
    my $self = {};

    $class = ref($class) if ref($class);
    $self = $class->SUPER::new($pdf, $parent);
    $self->{'Type'} = PDFName('Page');
    $self->proc_set(qw( PDF Text ImageB ImageC ImageI ));
    delete $self->{'Count'};
    delete $self->{'Kids'};
    $parent->add_page($self, $index);

    # copy global UU (if exists) to local, possibly to be overridden
    # we can access UserUnit (should be not 1.0, if exists) but not userUnit
    if (defined $self->{'Parent'}->{'UserUnit'}) {
	my $UU = $self->{'Parent'}->{'UserUnit'}->{'val'};
        $self->{' userUnit'} = $UU;
	# AND set the local one if global is not 1.0
	# (some readers don't let a page inherit the global UU)
	if ($UU != 1.0) {
	    $self->userunit($UU);
        }
    } else {
	# not setting a global userUnit, so default this one to 1.0
        $self->{' userUnit'} = 1;
	# don't set a local UserUnit for now
    }

    return $self;
}

#=item $page = PDF::Builder::Page->coerce($pdf, $pdfpage)
#
#Returns a page object converted from $pdfpage (called from $pdf->open_page()).
#
#=cut

# appears to be unused TBD

sub coerce {
    my ($class, $pdf, $page) = @_;
    my $self = $page;
    bless $self, $class;
    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};
    return $self;
}

#=item $page->update()
#
#Marks a page to be updated (by $pdf->update()).
#
#=cut

# appears to be internal routine
# replace any use by call to out_obj: $self->{' apipdf'}->out_obj($self);

# PDF::API2 2.042: DEPRECATED
# Marking the page as dirty should only be needed in rare cases
# when the page hash is being edited directly rather than through the API. In
# that case, the out_obj call can be made manually. There's no reason (that I
# can think of) to have a specific call just (and only) for Page objects.

sub update {
    my $self = shift;

    $self->{' apipdf'}->out_obj($self);
    return $self;
}

=back

=head2 Page Size Methods

=over

=item $page->userunit($value)

Sets the User Unit for this one page.  
See L<PDF::Builder::Docs/User Units> for more information.

=cut

sub userunit {
    my ($self, $value) = @_;

    if (float($value) <= 0.0) {
	warn "Invalid User Unit value '$value', set to 1.0";
	$value = 1.0;
    }

    # assume that even if $value is 1.0, it's being called for some reason
    # (perhaps overriding non-1.0 global setting)
    $PDF::Builder::global_pdf->verCheckOutput(1.6, "set User Unit");
    $self->{' userUnit'} = float($value);  # this is local (page) UU
    $self->{'UserUnit'} = PDFNum(float($value));

    return $self;
}

sub _bbox {
    my ($box, $self, @corners) = @_;
    # $box is the box name (e.g., MediaBox)
    # $self points to the page object
    # at least one element in @corners if setting. get if no elements.

    # if 1 or 3 elements in @corners, and [0] contains a letter, it's a name
    my $isName = 0;
    if (scalar @corners && $corners[0] =~ m/[a-z]/i) { $isName = 1; }

    if (scalar @corners == 0) {
	# is a query ('get')
	#   if previously set for this page, just return array
	#   if not set, check parent (PDF), then up chain as far as MediaBox
	if (defined $self->{$box}) {
	    return map { $_->val() } $self->{$box}->elements();
	} else {
            my $pdf = $self->{' api'};
            if (defined $pdf->{'pages'}->{$box}) {
                # parent (global) box is defined
                return map { $_->val() } $pdf->{'pages'}->{$box}->elements();
            } else {
                # go up the chain until find defined global
                if ($box eq 'ArtBox' || $box eq 'TrimBox' || $box eq 'BleedBox') {
            	    $box = 'CropBox';
                }
                if ($box eq 'CropBox' && !defined $pdf->{'pages'}->{'CropBox'}) {
            	    $box = 'MediaBox';
                }
                if ($box ne 'CropBox' && $box ne 'MediaBox') {
            	    # invalid box name. silent error: just return Media Box
            	    $box = 'MediaBox';
                }
                return map { $_->val() } $pdf->{'pages'}->{$box}->elements();
            }
	}
	
    } elsif (scalar @corners == 3) {
	# have a name and one option (orient)
	my ($name, %opts) = @corners;
	# copy dashed option names to preferred undashed names
	if (defined $opts{'-orient'} && !defined $opts{'orient'}) { $opts{'orient'} = delete($opts{'-orient'}); }

        @corners = page_size(($name)); # now 4 numeric values
	if (defined $opts{'orient'}) {
	    if ($opts{'orient'} =~ m/^l/i) { # 'landscape' or just 'l'
                # 0 0 W H -> 0 0 H W
		my $temp;
		$temp = $corners[2]; $corners[2] = $corners[3]; $corners[3] = $temp;
	    }
	}
    } else {
	# name without [orient] option, or numeric coordinates given
        @corners = page_size(@corners);
    }

    # scale down size if User Unit given (e.g., Letter => 0 0 8.5 11)
    # we have a global userUnit, and possibly a page userUnit overriding it
    if ($isName) {
        my $UU = $self->{' userUnit'};
        if ($UU != 1.0) {
	    for (my $i=0; $i<4; $i++) {
	        $corners[$i] /= $UU;
	    }
        }
    }

    $self->{$box} = PDFArray( map { PDFNum(float($_)) } @corners );
    # return 4 element array of box corners
    return @corners;
}

=item $page->mediabox($alias)

=item $page->mediabox($alias, 'orient' => 'orientation')

=item $page->mediabox($w,$h)

=item $page->mediabox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $page->mediabox()

Sets or gets the Media Box for this one page.  
See L<PDF::Builder::Docs/Media Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub mediabox {
    return _bbox('MediaBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_mediabox()

Gets the Media Box corner coordinates based on best estimates or the default.
These are in the order given in a mediabox call (4 coordinates).

This method is B<Deprecated>, and will likely be removed in the future. Use
the global (C<$pdf>) or page (C<$page>) mediabox() call with no parameters
instead.

=cut

sub get_mediabox {
    my $self = shift();
    return $self->mediabox();
}

=item $page->cropbox($alias)

=item $page->cropbox($alias, 'orient' => 'orientation')

=item $page->cropbox($w,$h)

=item $page->cropbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $page->cropbox()

Sets or gets the Crop Box for this one page.  
See L<PDF::Builder::Docs/Crop Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub cropbox {
    return _bbox('CropBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_cropbox()

Gets the Crop Box based on best estimates or the default.

This method is B<Deprecated>, and will likely be removed in the future. Use
the global (C<$pdf>) or page (C<$page>) cropbox() call with no parameters
instead.

=cut

sub get_cropbox {
    my $self = shift();
    return $self->cropbox();
}

=item $page->bleedbox($alias)

=item $page->bleedbox($alias, 'orient' => 'orientation')

=item $page->bleedbox($w,$h)

=item $page->bleedbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $page->bleedbox()

Sets or gets or gets the Bleed Box for this one page.  
See L<PDF::Builder::Docs/Bleed Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub bleedbox {
    return _bbox('BleedBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_bleedbox()

Gets the Bleed Box based on best estimates or the default.

This method is B<Deprecated>, and will likely be removed in the future. Use
the global (C<$pdf>) or page (C<$page>) bleedbox() call with no parameters
instead.

=cut

sub get_bleedbox {
    my $self = shift();
    return $self->bleedbox();
}

=item $page->trimbox($alias)

=item $page->trimbox($alias, 'orient' => 'orientation')

=item $page->trimbox($w,$h)

=item $page->trimbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $page->trimbox()

Sets or gets the Trim Box for this one page.  
See L<PDF::Builder::Docs/Trim Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub trimbox {
    return _bbox('TrimBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_trimbox()

Gets the Trim Box based on best estimates or the default.

This method is B<Deprecated>, and will likely be removed in the future. Use
the global (C<$pdf>) or page (C<$page>) trimbox() call with no parameters
instead.

=cut

sub get_trimbox {
    my $self = shift();
    return $self->trimbox();
}

=item $page->artbox($alias)

=item $page->artbox($alias, 'orient' => 'orientation')

=item $page->artbox($w,$h)

=item $page->artbox($llx,$lly, $urx,$ury)

=item ($llx,$lly, $urx,$ury) = $page->artbox()

Sets or gets the Art Box for this one page.  
See L<PDF::Builder::Docs/Art Box> for more information.
The method always returns the current bounds (after any set operation).

=cut

sub artbox {
    return _bbox('ArtBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_artbox()

Gets the Art Box based on best estimates or the default.

This method is B<Deprecated>, and will likely be removed in the future. Use
the global (C<$pdf>) or page (C<$page>) artbox() call with no parameters
instead.

=cut

sub get_artbox {
    my $self = shift();
    return $self->artbox();
}

=item $page->rotate($deg)

Rotates the page by the given degrees, which must be a multiple of 90.
An angle that is not a multiple of 90 will be rounded to the nearest 90 
degrees, with a message.

Note that the rotation angle is I<clockwise> for a positive amount!
E.g., a rotation of +90 (or -270) will have the bottom edge of the paper at
the left of the screen.
After rotating the page 180 degrees, C<[0, 0]> (originally lower left corner)
will be be in the top right corner of the page, rather than the bottom left.
X will increase to the right, and Y will increase downward.

(This allows you to auto-rotate to landscape without changing the mediabox!
There are other ways to accomplish this end, such as using the C<size()>
method, which will not change the coordinate system (move the origin).)

Do not confuse this C<rotate()> call with the I<graphics context> rotation 
(Content.pm) C<rotate()>, which permits any angle, is of opposite direction, 
and does not shift the origin!

B<Alternate name:> C<rotation>

This has been added for PDF::API2 compatibility.

=cut

sub rotation { return rotate(@_); } ## no critic

sub rotate {
    my ($self, $degrees) = @_;

    $degrees //= 0;
    # Ignore rotation of 360 or more (in either direction)
    $degrees = $degrees % 360; # range [0, 360)

    if ($degrees % 90) {
      my $deg = int(($degrees + 45)/90)*90;
      carp "page rotate($degrees) invalid, not multiple of 90 degrees.\nChanged to $deg";
      $degrees = $deg;
    }

    $self->{'Rotate'} = PDFNum($degrees);

    return $self;
}

=item $page->size($size)  # Set

=item @rectangle = $page->size()  # Get

Set the physical page size or return the coordinates of the rectangle enclosing
the physical page size.
This is an alternate method provided for compatibility with PDF::API2.

    # Set the physical page (media) size using a common size name
    $page->size('letter');

    # Set the page size using coordinates in points (X1, Y1, X2, Y2)
    $page->size([0, 0, 612, 792]);

    # Get the page coordinates in points
    my @rectangle = $page->size();

See Page Sizes below for possible values.
The size method is a convenient shortcut for setting the PDF's media box when
other prepress (print-related) page boundaries aren't required. It's equivalent 
to the following:

    # Set
    $page = $page->boundaries('media' => $size);

    # Get
    @rectangle = $page->boundaries()->{'media'}->@*;

=cut
   
sub size {
    my $self = shift;

    if (@_) { # Set (also returns object, for easy chaining)
	return $self->boundaries('media' => @_); 
    } else { # Get
	my %boundaries = $self->boundaries();
	return @{ $boundaries{'media'} };
    }
}

=item $page = $page->boundaries(%boundaries)

=item \%boundaries = $page->boundaries()

Set prepress page boundaries to facilitate printing. Returns the current page 
boundaries if called without arguments.
This is an alternate method provided for compatibility with PDF::API2.

    # Set
    $page->boundaries(
        # 13x19 inch physical sheet size
        'media' => '13x19',
        # sheet content is 11x17 with 0.25" bleed
        'bleed' => [0.75 * 72, 0.75 * 72, 12.25 * 72, 18.25 * 72],
        # 11x17 final trimmed size
        'trim'  => 0.25 * 72,
    );

    # Get
    %boundaries = $page->boundaries();
    ($x1,$y1, $x2,$y2) = $page->boundaries('trim');

The C<%boundaries> hash contains one or more page boundary keys (see Page
Boundaries) to set or replace, each with a corresponding size (see Page Sizes). 

If called without arguments, the returned hashref will contain (Get) all five 
boundaries. If called with one string argument, it returns the coordinates for 
the specified page boundary. If more than one boundary type is given, only the 
first is processed, and a warning is given that the remainder are ignored.

=back

=head3 Page Boundaries

PDF defines five page boundaries.  When creating PDFs for print shops, you'll
most commonly use just the media box and trim box.  Traditional print shops may
also use the bleed box when adding printer's marks and other information.

=over

=item media

The media box defines the boundaries of the physical medium on which the page is
to be printed.  It may include any extended area surrounding the finished page
for bleed, printing marks, or other such purposes. The default value is as
defined for PDF, a US letter page (8.5" x 11").

=item crop

The crop box defines the region to which the contents of the page shall be
clipped (cropped) when displayed or printed.  The default value is the page's
media box.
This is a historical page boundary. You'll likely want to set the bleed and/or
trim boxes instead.

=item bleed

The bleed box defines the region to which the contents of the page shall be
clipped when output in a production environment. This may include any extra
bleed area needed to accommodate the physical limitations of cutting, folding,
and trimming equipment. The actual printed page (media box) may include
printing marks that fall outside the bleed box. The default value is the page's
crop box.

=item trim

The trim box defines the intended dimensions of the finished page after
trimming. It may be smaller than the media box to allow for production-related
content, such as printing instructions, cut marks, or color bars. The default
value is the page's crop box.

=item art

The art box defines the extent of the page's meaningful content (including
potential white space) as intended by the page's creator. The default value is
the page's crop box.

=back

=head3 Page Sizes

PDF page sizes are stored as rectangular coordinates. For convenience, 
PDF::Builder also supports a number of aliases and shortcuts that are more 
human-friendly. The following formats are available:

=over

=item a standard paper size

    $page->boundaries('media' => 'A4');

Aliases for the most common paper sizes are built in (case-insensitive).
US: Letter, Legal, Ledger, Tabloid (and others)
Metric: 4A0, 2A0, A0 - A6, 4B0, 2B0, and B0 - B6 (and others)

=item a "WxH" string in inches

    $page->boundaries('media' => '8.5x11');

Many US paper sizes are commonly identified by their size in inches rather than
by a particular name. These can be passed as strings with the width and height
separated by an C<x>.
Examples: C<4x6>, C<12x18>, C<8.5x11>

=item a number representing a reduction (in points) from the next-larger box

For example, a 12" x 18" physical sheet to be trimmed down to an 11" x 17" sheet
can be specified as follows:

    # Note: There are 72 points per inch
    $page->boundaries('media' => '12x18', 'trim' => 0.5 * 72);

    # Equivalent
    $page->boundaries('media' => [0,        0,        12   * 72, 18   * 72],
                      'trim'  => [0.5 * 72, 0.5 * 72, 11.5 * 72, 17.5 * 72]);

This example shows a 12" x 18" physical sheet that will be reduced to a final
size of 11" x 17" by trimming 0.5" from each edge. The smaller page boundary is
assumed to be centered within the larger one.

The "next-larger box" follows this order, stopping at the first defined value:

    art -> trim -> bleed -> media
    crop -> media

This option isn't available for the media box, since it is by definition, the
largest boundary.

=item [$width, $height] in points

    $page->boundaries('media' => [8.5 * 72, 11 * 7.2]);

For other page or boundary sizes, the width and height (in points) can be given 
directly as an array.

=item [$x1, $y1, $x2, $y2] in points

    $page->boundaries('media' => [0, 0, 8.5 * 72, 11 * 72]);

Finally, the absolute (raw) coordinates of the bottom-left and top-right corners
of a rectangle can be specified.

=cut

sub _to_rectangle {
    my $value = shift();

    # An array of two or four numbers in points
    if (ref($value) eq 'ARRAY') {
        if      (@$value == 2) {
            return (0, 0, @$value);
        } elsif (@$value == 4) {
            return @$value;
        }
        croak "Page boundary array must contain two or four numbers";
    }

    # WxH in inches
    if ($value =~ /^([0-9.]+)\s*x\s*([0-9.]+)$/) {
        my ($w, $h) = ($1, $2);
        if (looks_like_number($w) and looks_like_number($h)) {
            return (0, 0, $w * 72, $h * 72);
        }
    }

    # Common names for page sizes
    my %page_sizes = PDF::Builder::Resource::PaperSizes::get_paper_sizes();

    if ($page_sizes{lc $value}) {
        return (0, 0, @{$page_sizes{lc $value}});
    }

    if (ref($value)) {
        croak "Unrecognized page size";
    } else {
        croak "Unrecognized page size: $value";
    }
}

sub boundaries {
    my $self = shift();

    # Get
    if      (@_ == 0) {  # empty list -- do all boxes
        my %boundaries;
        foreach my $box (qw(Media Crop Bleed Trim Art)) {
            $boundaries{lc($box)} = [$self->_bounding_box($box . 'Box')];
        }
        return %boundaries;
    } elsif (@_ == 1) {  # request one specific box
        my $box = shift();
       # apparently it is normal to have an array of boxes, and use only first
       #if (@_) { # more than one box in arg list?
       #    carp "More than one box requested for boundaries(). Using only first ($box)";
       #}
        my @coordinates = $self->_bounding_box(ucfirst($box) . 'Box');
        return @coordinates;
    }

    # Set
    my %boxes = @_;
    foreach my $box (qw(media crop bleed trim art)) {
        next unless exists $boxes{$box};

        # Special case: A single number as the value for anything other than
        # MediaBox means to take the next larger size and reduce it by this
        # amount in points on all four sides, provided the larger size was also
        # included.
        my $value = $boxes{$box};
        my @rectangle;
        if ($box ne 'media' and not ref($value) and looks_like_number($value)) {
            my $parent = ($box eq 'crop'  ? 'media' :
                          $box eq 'bleed' ? 'media' :
                          $box eq 'trim'  ? 'bleed' : 'trim');
            $parent = 'bleed' if $parent eq 'trim'  and not $boxes{'trim'};
            $parent = 'media' if $parent eq 'bleed' and not $boxes{'bleed'};
            $parent = 'media' if $parent eq 'bleed' and not $boxes{'bleed'};
            unless ($boxes{$parent}) {
                croak "Single-number argument for $box requires $parent";
            }

            @rectangle = @{$boxes{$parent}};
            $rectangle[0] += $value;
            $rectangle[1] += $value;
            $rectangle[2] -= $value;
            $rectangle[3] -= $value;
        }
        else {
            @rectangle = _to_rectangle($value);
        }

        my $box_name = ucfirst($box) . 'Box';
        $self->_bounding_box($box_name, @rectangle);
        $boxes{$box} = [@rectangle];
    }

    return $self;
}

sub _bounding_box {
    my $self = shift();
    my $type = shift();

    # Get
    unless (scalar @_) {
        my $box = $self->find_prop($type);
        unless ($box) {
            # Default to letter (for historical PDF::API2 reasons, not per the
            # PDF specification)
            return (0, 0, 612, 792) if $type eq 'MediaBox';

            # Use defaults per PDF 1.7 section 14.11.2 Page Boundaries
            return $self->_bounding_box('MediaBox') if $type eq 'CropBox';
            return $self->_bounding_box('CropBox');
        }
        return map { $_->val() } $box->elements();
    }

    # Set
    $self->{$type} = PDFArray(map { PDFNum(float($_)) } page_size(@_));
    return $self;
}

sub fixcontents {
    my ($self) = @_;

    $self->{'Contents'} = $self->{'Contents'} || PDFArray();
    if (ref($self->{'Contents'}) =~ /Objind$/) {
        $self->{'Contents'}->realise();
    }
    if (ref($self->{'Contents'}) !~ /Array$/) {
        $self->{'Contents'} = PDFArray($self->{'Contents'});
    }
    return;
}

sub content {
    my ($self, $obj, $dir) = @_;

    if (defined($dir) && $dir > 0) {
        $self->precontent($obj);
    } else {
        $self->addcontent($obj);
    }
    $self->{' apipdf'}->new_obj($obj) unless $obj->is_obj($self->{' apipdf'});
    $obj->{' apipdf'} = $self->{' apipdf'};
    $obj->{' api'} = $self->{' api'};
    $obj->{' apipage'} = $self;

    weaken $obj->{' apipdf'};
    weaken $obj->{' api'};
    weaken $obj->{' apipage'};

    return $obj;
}

sub addcontent {
    my ($self, @objs) = @_;

    $self->fixcontents();
    $self->{'Contents'}->add_elements(@objs);
    return;
}

sub precontent {
    my ($self, @objs) = @_;

    $self->fixcontents();
    unshift(@{$self->{'Contents'}->val()}, @objs);
    return;
}

=item $gfx = $page->gfx(%opts)

=item $gfx = $page->gfx($prepend)

=item $gfx = $page->gfx()

Returns a graphics content object, for drawing paths and shapes. 

You may specify the "prepend" flag in the old or new way. The old way is to
give a single boolean value (0 false, non-zero true). The new way is to give
a hash element named 'prepend', with the same values.

=over

=item gfx(boolean_value $prepend)

=item gfx('prepend' => boolean_value)

=back

If $prepend is I<true>, or the option 'prepend' is given with a I<true> value, 
the content will be prepended to the page description (at the beginning of 
the page's content stream).
Otherwise, it will be appended.
The default is I<false>.

=over

=item gfx('compress' => boolean_value)

=back

You may specify a compression flag saying whether the drawing instructions
are to be compressed. If not given, the default is for the overall PDF
compression setting to be used (I<on> by default).

You may have more than one I<gfx> object. They and I<text> objects will be 
output as objects and streams I<in the order defined>, with all actions pertaining
to this I<gfx> object appearing in one stream. However, note that graphics 
and text objects are not fully independent of each other: the exit state 
(linewidth, strokecolor, etc.) of one object is the entry state of the next 
object in line to be output, and so on. 

If you intermix multiple I<gfx> and I<text> objects on
a page, the results may be confusing. Say you have $gfx1, $text1, $gfx2, and
$text2 on your page (I<created in that order>). PDF::Builder will output all the
$gfx1->I<action> calls in one stream, then all the $text1->I<action> calls in
the next stream, and likewise for $gfx2 usage and finally $text2. 

Then it's PDF's turn to confuse you. PDF will process the entire $gfx1 object
stream, accumulating the graphics state to the end of the stream, and using 
that as the entry state into $text1. In a similar manner, $gfx2 and $text2 are
read, processed, and rendered. Thus, a change in, say, the dash pattern in the
middle of $gfx1, I<after> you have output some $gfx2, $text1, and $text2 
material, may suddenly show up at the beginning of $text1 (and continue through 
$gfx2 and $text2)!

It is possible to use multiple graphics objects, to avoid having to change
settings constantly, but you may want to consider resetting all your settings 
at the first call to each object, so that you are starting from a known base.
This may most easily be done by using $I<type>->restore() and ->save() just
after creating $I<type>:

=over

 $text1 = $page->text(); 
   $text1->save();
 $grfx1 = $page->gfx();
   $grfx1->restore();
   $grfx1->save();
 $text2 = $page->text();
   $text2->restore();
   $text2->save();
 $grfx2 = $page->gfx();
   $grfx1->restore();

=back

B<Alternate name:> C<graphics>

This has been added for PDF::API2 compatibility.

=cut

sub graphics { return gfx(@_); } ## no critic

sub gfx {
    my ($self, @params) = @_;

    my ($prepend, $compress);
    $prepend = $compress = 0; # default for both is False
    if (scalar @params == 0) {
	# gfx() call. no change
    } elsif (scalar @params == 1) {
	# one scalar value, $prepend
	$prepend = $params[0];
    } elsif ((scalar @params)%2) {
	# odd number of values, can't be a hash list
	carp "Invalid parameters passed to gfx or graphics call!";
    } else {
	# hash list with at least one element
	my %hash = @params;
	# copy dashed hash names to preferred undashed names
	if (defined $hash{'-prepend'} && !defined $hash{'prepend'}) { $hash{'prepend'} = delete($hash{'-prepend'}); }
	if (defined $hash{'-compress'} && !defined $hash{'compress'}) { $hash{'compress'} = delete($hash{'-compress'}); }

	if (defined $hash{'prepend'}) { $prepend = $hash{'prepend'}; }
	if (defined $hash{'compress'}) { $compress = $hash{'compress'}; }
    }
    if ($prepend) { $prepend = 1; }
    $compress //= $self->{' api'}->{'forcecompress'} eq 'flate' ||
                  $self->{' api'}->{'forcecompress'} =~ m/^[1-9]\d*$/;

    my $gfx = PDF::Builder::Content->new();
    $gfx->compressFlate() if $compress;
    $self->content($gfx, $prepend);

    return $gfx;
}

=item $text = $page->text(%opts)

=item $text = $page->text($prepend)

=item $text = $page->text()

Returns a text content object, for writing text.
See L<PDF::Builder::Content> for details.

You may specify the "prepend" flag in the old or new way. The old way is to
give a single boolean value (0 false, non-zero true). The new way is to give
a hash element named 'prepend', with the same values.

=over

=item text(boolean_value $prepend)

=item text('prepend' => boolean_value)

=back

If $prepend is I<true>, or the option 'prepend' is given with a I<true> value, 
the content will be prepended to the page description (at the beginning of 
the page's content stream).
Otherwise, it will be appended.
The default is I<false>.

=over

=item text('compress' => boolean_value)

=back

You may specify a compression flag saying whether the text content is 
to be compressed. If not given, the default is for the overall PDF
compression setting to be used (I<on> by default).

Please see the discussion above in C<gfx()> regarding multiple graphics and
text objects on one page, how they are grouped into PDF objects and streams, 
and the rendering consequences of running through one entire object at a time,
before moving on to the next.

The I<text> object has many settings and attributes of its own, but shares many
with graphics (I<gfx>), such as strokecolor, fillcolor, linewidth, linedash,
and the like. Thus there is some overlap in attributes, and graphics and text
calls can affect each other.

=cut

sub text {
    my ($self, @params) = @_;

    my ($prepend, $compress);
    $prepend = $compress = 0; # default for both is False
    if (scalar @params == 0) {
	# text() call. no change
    } elsif (scalar @params == 1) {
	# one scalar value, $prepend
	$prepend = $params[0];
    } elsif ((scalar @params)%2) {
	# odd number of values, can't be a hash list
	carp "Invalid parameters passed to text() call!";
    } else {
	# hash list with at least one element
	my %hash = @params;
	# copy dashed hash names to preferred undashed names
	if (defined $hash{'-prepend'} && !defined $hash{'prepend'}) { $hash{'prepend'} = delete($hash{'-prepend'}); }
	if (defined $hash{'-compress'} && !defined $hash{'compress'}) { $hash{'compress'} = delete($hash{'-compress'}); }

	if (defined $hash{'prepend'}) { $prepend = $hash{'prepend'}; }
	if (defined $hash{'compress'}) { $compress = $hash{'compress'}; }
    }
    if ($prepend) { $prepend = 1; }
    $compress //= $self->{' api'}->{'forcecompress'} eq 'flate' ||
                  $self->{' api'}->{'forcecompress'} =~ m/^[1-9]\d*$/;

    my $text = PDF::Builder::Content::Text->new();
    $text->compressFlate() if $compress;
    $self->content($text, $prepend);

    return $text;
}

=item $page = $page->object($object, $x,$y, $scale_x,$scale_y)

Places an image or other external object (a.k.a. XObject) on the page in the
specified location.

For images, C<$scale_x> and C<$scale_y> represent the width and height of the
image on the page in points.  If C<$scale_x> is omitted, it will default to 72
pixels per inch.  If C<$scale_y> is omitted, the image will be scaled
proportionally based on the image dimensions.

For other external objects, the scale is a multiplier, where 1 (the default)
represents 100% (i.e. no change).

If the object to be placed depends on a coordinate transformation (e.g. rotation
or skew), first create a content object using L</"graphics">, then call
L<PDF::Builder::Content/"object"> after making the appropriate transformations.

=cut

sub object {
    my $self = shift();
    $self->graphics()->object(@_);
    return $self;
}

=item $ant = $page->annotation()

Returns a new annotation object.

=cut

sub annotation {
    my $self = shift;

    unless (exists $self->{'Annots'}) {
        $self->{'Annots'} = PDFArray();
        $self->{' apipdf'}->out_obj($self);
    } elsif (ref($self->{'Annots'}) =~ /Objind/) {
        $self->{'Annots'}->realise();
    }

    require PDF::Builder::Annotation;
    my $ant = PDF::Builder::Annotation->new();
    $self->{'Annots'}->add_elements($ant);
    $self->{' apipdf'}->new_obj($ant);
    $ant->{' apipdf'} = $self->{' apipdf'};
    $ant->{' apipage'} = $self;
    weaken $ant->{' apipdf'};
    weaken $ant->{' apipage'};

    if ($self->{'Annots'}->is_obj($self->{' apipdf'})) {
        $self->{' apipdf'}->out_obj($self->{'Annots'});
    }

    return $ant;
}

=item $page->resource($type, $key, $obj)

Adds a resource to the page-inheritance tree.

B<Example:>

    $co->resource('Font', $fontkey, $fontobj);
    $co->resource('XObject', $imagekey, $imageobj);
    $co->resource('Shading', $shadekey, $shadeobj);
    $co->resource('ColorSpace', $spacekey, $speceobj);

B<Note:> You only have to add the required resources if
they are NOT handled by the *font*, *image*, *shade* or *space*
methods.

=cut

sub resource {
    my ($self, $type, $key, $obj, $force) = @_;

    my $dict = $self->find_prop('Resources');

    $dict = $dict || $self->{'Resources'} || PDFDict();

    $dict->realise() if ref($dict) =~ /Objind$/;

    $dict->{$type} = $dict->{$type} || PDFDict();
    $dict->{$type}->realise() if ref($dict->{$type}) =~ /Objind$/;

    unless (defined $obj) {
        return $dict->{$type}->{$key} || undef;
    } else {
        if ($force) {
            $dict->{$type}->{$key} = $obj;
        } else {
            $dict->{$type}->{$key} = $dict->{$type}->{$key} || $obj;
        }

        $self->{' apipdf'}->out_obj($dict) if $dict->is_obj($self->{' apipdf'});
        $self->{' apipdf'}->out_obj($dict->{$type}) if $dict->{$type}->is_obj($self->{' apipdf'});
        $self->{' apipdf'}->out_obj($obj) if $obj->is_obj($self->{' apipdf'});
        $self->{' apipdf'}->out_obj($self);

        return $dict;
    }
}

sub ship_out {
    my ($self, $pdf) = @_;

    $pdf->ship_out($self);
    if (defined $self->{'Contents'}) {
        $pdf->ship_out($self->{'Contents'}->elements());
    }
    return $self;
}

#sub outobjdeep {
#    my ($self, @opts) = @_;
#
#    foreach my $k (qw/ api apipdf /) {
#        $self->{" $k"} = undef;
#        delete($self->{" $k"});
#    }
#    return $self->SUPER::outobjdeep(@opts);
#}

=back

=cut

1;
