package PDF::Builder::Page;

use base 'PDF::Builder::Basic::PDF::Pages';

use strict;
use warnings;

our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

use POSIX qw(floor);
use Scalar::Util qw(weaken);

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Content;
use PDF::Builder::Content::Text;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Page - Methods to interact with individual pages

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
#Returns a page object converted from $pdfpage (called from $pdf->openpage()).
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

sub update {
    my ($self) = @_;

    $self->{' apipdf'}->out_obj($self);
    return $self;
}

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
    PDF::Builder->verCheckOutput(1.6, "set User Unit");
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
	# have a name and one option (-orient)
	my ($name, %opts) = @corners;
        @corners = page_size(($name)); # now 4 numeric values
	if (defined $opts{'-orient'}) {
	    if ($opts{'-orient'} =~ m/^l/i) { # 'landscape' or just 'l'
                # 0 0 W H -> 0 0 H W
		my $temp;
		$temp = $corners[2]; $corners[2] = $corners[3]; $corners[3] = $temp;
	    }
	}
    } else {
	# name without [-orient] option, or numeric coordinates given
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

=item $page->mediabox($alias, -orient => 'orientation')

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

=item $page->cropbox($alias, -orient => 'orientation')

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

=item $page->bleedbox($alias, -orient => 'orientation')

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

=item $page->trimbox($alias, -orient => 'orientation')

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

=item $page->artbox($alias, -orient => 'orientation')

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

(This allows you to auto-rotate to landscape without changing the mediabox!)

Do not confuse this C<rotate()> call with the I<graphics context> rotation 
(Content.pm) C<rotate()>, which permits any angle, is of opposite direction, 
and does not shift the origin!

=cut

sub rotate {
    my ($self, $degrees) = @_;

    # Ignore rotation of 360 or more (in either direction)
    $degrees = $degrees % 360; # range [0, 360)
    if ($degrees % 90) {
      my $deg = int(($degrees + 45)/90)*90;
      warn "page rotate($degrees) invalid, not multiple of 90 degrees.\nChanged to $deg";
      $degrees = $deg;
    }

    $self->{'Rotate'} = PDFNum($degrees);

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

=item $gfx = $page->gfx($prepend)

=item $gfx = $page->gfx()

Returns a graphics content object. 
If $prepend is I<true>, the content will be prepended to the page description.
Otherwise, it will be appended.

You may have more than one I<gfx> object. They and I<text> objects will be 
output as objects and streams in the order defined, with all actions pertaining
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

=cut

sub gfx {
    my ($self, $prepend) = @_;

    my $gfx = PDF::Builder::Content->new();
    $self->content($gfx, $prepend);
    $gfx->compressFlate() if ($self->{' api'}->{'forcecompress'} eq 'flate' ||
                              $self->{' api'}->{'forcecompress'} =~ m/^[1-9]\d*$/);

    return $gfx;
}

=item $txt = $page->text($prepend)

=item $txt = $page->text()

Returns a text content object. 
If $prepend is I<true>, the content will be prepended to the page description.
Otherwise, it will be appended.

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
    my ($self, $prepend) = @_;

    my $text = PDF::Builder::Content::Text->new();
    $self->content($text, $prepend);
    $text->compressFlate() if ($self->{' api'}->{'forcecompress'} eq 'flate' ||
                               $self->{' api'}->{'forcecompress'} =~ m/^[1-9]\d*$/);

    return $text;
}

=item $ant = $page->annotation()

Returns a new annotation object.

=cut

sub annotation {
    my $self = shift;

    unless (exists $self->{'Annots'}) {
        $self->{'Annots'} = PDFArray();
        $self->update();
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
