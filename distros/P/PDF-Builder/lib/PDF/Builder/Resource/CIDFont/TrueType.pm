package PDF::Builder::Resource::CIDFont::TrueType;

use base 'PDF::Builder::Resource::CIDFont';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::CIDFont::TrueType::FontFile;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::CIDFont::TrueType - TrueType font support

=head1 METHODS

=head2 new

    $font = PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $file, %options)

=over

Returns a font object.

Defined Options:

    encode ... specify fonts encoding for non-UTF-8 text.

    nosubset ... disables subsetting. Any value causes the full font to be
                 embedded, rather than only the glyphs needed.

=back

=cut

sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-nosubset'} && !defined $opts{'nosubset'}) { $opts{'nosubset'} = delete($opts{'-nosubset'}); }
    if (defined $opts{'-noembed'} && !defined $opts{'noembed'}) { $opts{'noembed'} = delete($opts{'-noembed'}); }
    if (defined $opts{'-dokern'} && !defined $opts{'dokern'}) { $opts{'dokern'} = delete($opts{'-dokern'}); }

    $opts{'encode'} //= 'latin1';
    my ($ff, $data) = PDF::Builder::Resource::CIDFont::TrueType::FontFile->new($pdf, $file, %opts);

    $class = ref $class if ref $class;
#   my $self = $class->SUPER::new($pdf, $data->{'apiname'}.pdfkey().'~'.time());
    my $self = $class->SUPER::new($pdf, $data->{'apiname'} . pdfkey());
    $pdf->new_obj($self) if defined($pdf) && !$self->is_obj($pdf);

    $self->{' data'} = $data;

    $self->{'BaseFont'} = PDFName($self->fontname());

    my $des = $self->descrByData();
    my $de = $self->{' de'};

    $de->{'FontDescriptor'} = $des;
    $de->{'Subtype'} = PDFName($self->iscff()? 'CIDFontType0': 'CIDFontType2');
    ## $de->{'BaseFont'} = PDFName(pdfkey().'+'.($self->fontname()).'~'.time());
    $de->{'BaseFont'} = PDFName($self->fontname());
    $de->{'DW'} = PDFNum($self->missingwidth());
    if (($opts{'noembed'}||0) != 1) {
    	$des->{$self->data()->{'iscff'}? 'FontFile3': 'FontFile2'} = $ff;
    }
    unless ($self->issymbol()) {
        $self->encodeByName($opts{'encode'});
        $self->data->{'encode'} = $opts{'encode'};
        $self->data->{'decode'} = 'ident';
    }

    if ($opts{'nosubset'}) {
        $self->data()->{'nosubset'} = 1;
    }

    $self->{' ff'} = $ff;
    $pdf->new_obj($ff);

    $self->{'-dokern'} = 1 if $opts{'dokern'};

    return $self;
}

=head2 fontfile

    $font->fontfile()

=over

Returns font file object (' ff' element), so its methods may be invoked.

=back

=cut

sub fontfile { 
    return $_[0]->{' ff'};
}

=head2 fontobj

    $font->fontobj()

=over

Returns font object, so its methods and properties may be used.

=back

=cut

sub fontobj {
    return $_[0]->data()->{'obj'};
}

=head2 wxByCId

    $font->wxByCId($gID)

=over

Returns unscaled glyph width, given the glyph ID (CID).

=back

=cut

sub wxByCId {
    my ($self, $g) = @_;

    my $t = $self->fontobj()->{'hmtx'}->read()->{'advance'}[$g];
    my $w;

    if (defined $t) {
        $w = int($t *1000/$self->data()->{'upem'});
    } else {
        $w = $self->missingwidth();
    }

    return $w;
}

=head2 haveKernPairs

    $flag = $font->haveKernPairs()

=over

Does the font include kerning data? Invokes fontfile's haveKernPairs().
Not clear what additional optional arguments are.

=back

=cut

sub haveKernPairs {
    my $self = shift;

    return $self->fontfile()->haveKernPairs(@_);
}

=head2 kernPairCid

    $flag = $font->kernPairCid($gID, $n)

=over

Returns kerning information for? Not clear what additional arguments are.
Invokes fontfile's kernPairCid() method.

=back

=cut

sub kernPairCid {
    my $self = shift;

    return $self->fontfile()->kernPairCid(@_);
}

=head2 subsetByCid

    $font->subsetByCid($gID)

=over

Invokes subsetByCId() method from fontfile() to put the glyph into the embedded
font cache in the PDF.

=back

=cut

sub subsetByCId {
    my $self = shift;

    return if $self->iscff();
    my $g = shift;
    return $self->fontfile()->subsetByCId($g);
}

=head2 subvec

    $font->subvec($gID)

=over

(No Information) invokes fontfile's subvec() method.

=back

=cut

sub subvec {
    my $self = shift;

    return 1 if $self->iscff();
    my $g = shift;
    return $self->fontfile()->subvec($g);
}

=head2 glyphNum

    $count = $font->glyphNum()

=over

Number of glyphs in the font.

=back

=cut

sub glyphNum {
    return $_[0]->fontfile()->glyphNum();
}

=head2 outobjdeep

    $font->outobjdeep()

=over

(No Information) output to PDF

=back

=cut

sub outobjdeep {
    my ($self, $fh, $pdf) = @_;

    my $notdefbefore = 1;

    my $wx = PDFArray();
    $self->{' de'}->{'W'} = $wx;
    my $ml;

    foreach my $w (0 .. (scalar @{$self->data()->{'g2u'}} - 1 )) {
        if      ($self->subvec($w) && $notdefbefore == 1) {
            $notdefbefore = 0;
            $ml = PDFArray();
            $wx->add_elements(PDFNum($w), $ml);
        #   $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
            $ml->add_elements(PDFNum($self->wxByCId($w)));
        } elsif ($self->subvec($w) && $notdefbefore == 0) {
        #   $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
            $ml->add_elements(PDFNum($self->wxByCId($w)));
        } else {
            $notdefbefore = 1;
        }
        # optimization for CJK
        #if ($self->subvec($w) && $notdefbefore == 1 && $self->data()->{'wx'}->[$w] != $self->missingwidth()) {
        #    $notdefbefore = 0;
        #    $ml = PDFArray();
        #    $wx->add_elements(PDFNum($w), $ml);
        #    $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
        #} elsif ($self->subvec($w) && $notdefbefore == 0 && $self->data()->{'wx'}->[$w] != $self->missingwidth()) {
        #    $notdefbefore = 0;
        #    $ml->add_elements(PDFNum($self->data()->{'wx'}->[$w]));
        #} else {
        #    $notdefbefore = 1;
        #}
    }

    return $self->SUPER::outobjdeep($fh, $pdf);
}

1;
