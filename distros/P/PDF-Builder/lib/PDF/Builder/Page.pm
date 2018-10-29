package PDF::Builder::Page;

use base 'PDF::Builder::Basic::PDF::Pages';

use strict;
use warnings;

our $VERSION = '3.012'; # VERSION
my $LAST_UPDATE = '3.011'; # manually update whenever code is changed

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
    my ($self) = {};

    $class = ref $class if ref $class;
    $self = $class->SUPER::new($pdf, $parent);
    $self->{'Type'} = PDFName('Page');
    $self->proc_set(qw( PDF Text ImageB ImageC ImageI ));
    delete $self->{'Count'};
    delete $self->{'Kids'};
    $parent->add_page($self, $index);
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
    bless ($self, $class);
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

=item $page->mediabox($w,$h)

=item $page->mediabox($llx,$lly, $urx,$ury)

=item $page->mediabox($alias)

Sets the mediabox.  This method supports the following aliases I<and more>:
'4A0', '2A0', 'A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6',
'4B0', '2B0', 'B0', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6',
'LETTER', 'BROADSHEET', 'LEDGER', 'TABLOID', 'LEGAL',
'EXECUTIVE', and '36X36'. 
See L<PDF::Builder::Resource::PaperSizes> code for the full list.

=cut

sub _set_bbox {
    my ($box, $self, @values) = @_;
    $self->{$box} = PDFArray( map { PDFNum(float($_)) } page_size(@values) );
    return $self;
}

sub _get_bbox {
    my ($self, $box_order) = @_;

    # Default to US letter
    my @media = (0, 0, 612, 792);

    foreach my $mediatype (@{$box_order}) {
        my $mediaobj = $self->find_prop($mediatype);
        if ($mediaobj) {
            @media = map { $_->val() } $mediaobj->elementsof();
            last;
        }
    }

    return @media;
}

sub mediabox {
    return _set_bbox('MediaBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_mediabox()

Gets the mediabox based on best estimates or the default.

=cut

sub get_mediabox {
    my $self = shift;

    return _get_bbox($self, [qw(MediaBox CropBox BleedBox TrimBox ArtBox)]);
}

=item $page->cropbox($w,$h)

=item $page->cropbox($llx,$lly, $urx,$ury)

=item $page->cropbox($alias)

Sets the cropbox. This method supports the same aliases as mediabox.

=cut

sub cropbox {
    return _set_bbox('CropBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_cropbox()

Gets the cropbox based on best estimates or the default.

=cut

sub get_cropbox {
    my $self = shift;

    return _get_bbox($self, [qw(CropBox MediaBox BleedBox TrimBox ArtBox)]);
}

=item $page->bleedbox($w,$h)

=item $page->bleedbox($llx,$lly, $urx,$ury)

=item $page->bleedbox($alias)

Sets the bleedbox. This method supports the same aliases as mediabox.

=cut

sub bleedbox {
    return _set_bbox('BleedBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_bleedbox()

Gets the bleedbox based on best estimates or the default.

=cut

sub get_bleedbox {
    my $self = shift;

    return _get_bbox($self, [qw(BleedBox CropBox MediaBox TrimBox ArtBox)]);
}

=item $page->trimbox($w,$h)

=item $page->trimbox($llx,$lly, $urx,$ury)

=item $page->trimbox($alias)

Sets the trimbox. This method supports the same aliases as mediabox.

=cut

sub trimbox {
    return _set_bbox('TrimBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_trimbox()

Gets the trimbox based on best estimates or the default.

=cut

sub get_trimbox {
    my $self = shift;

    return _get_bbox($self, [qw(TrimBox CropBox MediaBox ArtBox BleedBox)]);
}

=item $page->artbox($w,$h)

=item $page->artbox($llx,$lly, $urx,$ury)

=item $page->artbox($alias)

Sets the artbox. This method supports the same aliases as mediabox.

=cut

sub artbox {
    return _set_bbox('ArtBox', @_);
}

=item ($llx,$lly, $urx,$ury) = $page->get_artbox()

Gets the artbox based on best estimates or the default.

=cut

sub get_artbox {
    my $self = shift;

    return _get_bbox($self, [qw(ArtBox CropBox MediaBox TrimBox BleedBox)]);
}

=item $page->rotate($deg)

Rotates the page by the given degrees, which must be a multiple of 90.

(This allows you to auto-rotate to landscape without changing the mediabox!)

=cut

sub rotate {
    my ($self, $degrees) = @_;

    # Ignore rotation of 360 or more (in either direction)
    $degrees = $degrees % 360;

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

    if (defined($dir) && $dir) {
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

    unless  (exists $self->{'Annots'}) {
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

B<Note:> You only have to add the required resources, if
they are NOT handled by the *font*, *image*, *shade* or *space*
methods.

=cut

sub resource {
    my ($self, $type, $key, $obj, $force) = @_;

    my ($dict) = $self->find_prop('Resources');

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
        $pdf->ship_out($self->{'Contents'}->elementsof());
    }
    return $self;
}

sub outobjdeep {
    my ($self, @opts) = @_;

    foreach my $k (qw/ api apipdf /) {
        $self->{" $k"} = undef;
        delete($self->{" $k"});
    }
    return $self->SUPER::outobjdeep(@opts);
}

=back

=cut

1;
