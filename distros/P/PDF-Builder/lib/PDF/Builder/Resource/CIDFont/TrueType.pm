package PDF::Builder::Resource::CIDFont::TrueType;

use base 'PDF::Builder::Resource::CIDFont';

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Resource::CIDFont::TrueType::FontFile;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::CIDFont::TrueType - TrueType (ttfont) font support

Inherits from L<PDF::Builder::Resource::CIDFont>

Generally also usable for OTF (Open Type) fonts

=head1 METHODS

=head2 new

    $font = PDF::Builder::Resource::CIDFont::TrueType->new($pdf, $file, %opts)

=over

Returns a font object for TrueType and OpenType fonts (from C<ttfont()> call).

=back

Valid Options (%opts) are:

=over

=item encode

Changes the encoding of the font from its default (WinAnsiEncoding).

Note that for a single byte encoding (e.g., 'latin1'), you are limited to 256
characters defined for that encoding. 'automap' does not work with TrueType.
If you want more characters than that, use 'utf8' encoding with a UTF-8
encoded text string.

=item isocmap

Use the ISO Unicode Map instead of the default MS Unicode Map.

=item unicodemap

If 1 (default), output ToUnicode CMap to permit text searches and screen
readers. Set to 0 to save space by I<not> including the ToUnicode CMap, but
text searching and screen reading will not be possible.

=item dokern

Enables kerning if data is available.

C<kerning> is still accepted as an (older) B<alternative> to C<dokern>.

=item embed

If set (non-zero), which is the default, the font (entire or subsetted) will
be embedded in the PDF file. See the comments in C<noembed> about the possible
hazards of I<not> embedding the font, and limitations on embedding.

C<true> (non-zero) and C<false> (zero) are the values of C<embed>. It is 
possible that in the future, some non-zero values may get special meaning (such
as permission flags), so it is best to use only 0 and 1 for a value.

=item noembed

B<noembed> is I<ignored> if B<embed> I<is> given. C<noembed> is deprecated,
while C<embed> (default true) is preferred.

Disables embedding of the font file. B<Note that this is potentially hazardous,
as the glyphs provided on the PDF reader machine may not match what was used on
the PDF writer machine (the one running PDF::Builder)!> If you know I<for sure> 
that all PDF readers will be using the same TTF or OTF file you're using with
PDF::Builder; not embedding the font may be acceptable, in return for a smaller
PDF file size. Note that the Reader needs to know where to find the font file
-- it can't be in any random place, but typically needs to be listed in a path 
that the Reader follows. Otherwise, it will be unable to render the text!

Some additional comments on embedding font file(s) into the PDF: besides 
substantially increasing the size of the PDF (even if the font is subsetted,
by default), PDF::Builder does not check the font file for any flags indicating 
font licensing issues and limitations on use. A font foundry may not permit 
embedding at all, may permit a subset of the font to be embedded, may permit a 
full font to be embedded, and may specify what can be done with an embedded 
font (e.g., may or may not be extracted for further use beyond displaying this 
one PDF). When you choose to use (and embed) a font, you should be aware of any
such licensing issues.

=item nosubset

Disables subsetting of a TTF/OTF font, when embedded. By default, only the
glyphs used by a document are included in the file, and I<not> the entire font.
This can result in a tremendous savings in PDF file size. If you intend to 
allow the PDF to be edited by users, not having the entire font glyph set
available may cause problems, so be aware of that (and consider using 
C<< nosubset => 1 >>. Setting this flag to any value results in the entire
font glyph set being embedded in the file. It might be a good idea to use only
the value B<1>, in case other values are assigned roles in the future.

=item debug

If set to 1 (default is 0), diagnostic information is output about the CMap
processing.

=item usecmf

If set to 1 (default is 0), the first priority is to make use of one of the
four C<.cmap> files for CJK fonts. This is the I<old> way of processing TTF
files. If, after all is said and done, a working I<internal> CMap hasn't been
found (for usecmf=>0), C<ttfont()> will fall back to using a C<.cmap> file
if possible.

=item cmaps

This flag may be set to a string listing the Platform/Encoding pairs to look 
for of any internal CMaps in the font file, in the desired order (highest 
priority first). If one list (comma and/or space-separated pairs) is given, it 
is used for both Windows and non-Windows platforms (on which PDF::Builder is 
running, I<not> the PDF reader's). Two lists, separated by a semicolon ; may be 
given, with the first being used for a Windows platform and the second for 
non-Windows. The default list is C<0/6 3/10 0/4 3/1 0/3; 0/6 0/4 3/10 0/3 3/1>. 
Finally, instead of a P/E list, a string C<find_ms> may be given to tell it to 
simply call the Font::TTF C<find_ms()> method to find a (preferably Windows) 
internal CMap. C<cmaps> set to 'find_ms' would emulate the I<old> way of 
looking for CMaps. Symbol fonts (3/0) always use find_ms(), and the new default 
lookup is (if C<.cmap> isn't used, see C<usecmf>) to try to get a match with 
the default list for the appropriate OS. If none can be found, find_ms() is 
tried, and as last resort use the C<.cmap> (if available), even if C<usecmf> 
is not 1.

=back

=cut

sub new {
    my ($class, $pdf, $file, %opts) = @_;

    # copy dashed option names to preferred undashed names
    if (defined $opts{'-encode'} && !defined $opts{'encode'}) { $opts{'encode'} = delete($opts{'-encode'}); }
    if (defined $opts{'-nosubset'} && !defined $opts{'nosubset'}) { $opts{'nosubset'} = delete($opts{'-nosubset'}); }
    if (defined $opts{'-dokern'} && !defined $opts{'dokern'}) { $opts{'dokern'} = delete($opts{'-dokern'}); }

    # embed should already be set by ttfont(), so ignore noembed too
   #if (defined $opts{'-noembed'} && !defined $opts{'noembed'}) { $opts{'noembed'} = delete($opts{'-noembed'}); }
   #if (defined $opts{'-embed'} && !defined $opts{'embed'}) { $opts{'embed'} = delete($opts{'-embed'}); }

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
    if ($opts{'embed'}) {
	# TBD: check, API2 omits ->data() term
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

Returns unscaled glyph width, given its glyph ID (CID).

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

=head2 subsetByCId

    $font->subsetByCId($gID)

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
