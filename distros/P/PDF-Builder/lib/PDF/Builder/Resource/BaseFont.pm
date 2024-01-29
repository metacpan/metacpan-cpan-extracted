package PDF::Builder::Resource::BaseFont;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use Compress::Zlib;
#use Encode qw(:all);
use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::BaseFont - Base class for font resources

=head1 METHODS

=head2 new

    $font = PDF::Builder::Resource::BaseFont->new($pdf, $name)

=over

Return a font resource object.

=back

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self;

    $class = ref($class) if ref($class);
    $self = $class->SUPER::new($pdf, $name);

    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{'Type'} = PDFName('Font');

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    return $self;
}

sub data { 
    return $_[0]->{' data'}; 
}

=head2 descrByData

    $descriptor = $font->descrByData()

=over

Return the font's FontDescriptor key structure based on the font's data.

=back

=cut

sub descrByData {
    my $self = shift();

    my $descriptor = PDFDict();
    $self->{' apipdf'}->new_obj($descriptor);

    $descriptor->{'Type'}         = PDFName('FontDescriptor');
    $descriptor->{'FontName'}     = PDFName($self->fontname());

    my @box = map { PDFNum($_ || 0) } $self->fontbbox();
    $descriptor->{'FontBBox'}     = PDFArray(@box);

    $descriptor->{'Ascent'}       = PDFNum($self->ascender()     || 0);
    $descriptor->{'Descent'}      = PDFNum($self->descender()    || 0);
    $descriptor->{'ItalicAngle'}  = PDFNum($self->italicangle()  || 0.0);
    $descriptor->{'XHeight'}      = PDFNum($self->xheight()      || (($self->fontbbox())[3]*0.5) || 500);
    $descriptor->{'CapHeight'}    = PDFNum($self->capheight()    || ($self->fontbbox())[3] || 800);
    $descriptor->{'StemV'}        = PDFNum($self->stemv()        || 0);
    $descriptor->{'StemH'}        = PDFNum($self->stemh()        || 0);
    $descriptor->{'AvgWidth'}     = PDFNum($self->avgwidth()     || 300);
    $descriptor->{'MissingWidth'} = PDFNum($self->missingwidth() || 300);
    $descriptor->{'MaxWidth'}     = PDFNum($self->maxwidth()     || $self->missingwidth() || ($self->fontbbox())[2]);
    $descriptor->{'Flags'}        = PDFNum($self->flags()        || 0) unless $self->data()->{'iscore'};
    if (defined $self->data()->{'panose'}) {
        $descriptor->{'Style'}             = PDFDict();
        $descriptor->{'Style'}->{'Panose'} = PDFStrHex($self->data()->{'panose'});
    }
    $descriptor->{'FontFamily'}   = PDFString($self->data()->{'fontfamily'}, 'x')
        if defined $self->data()->{'fontfamily'};
    $descriptor->{'FontWeight'}   = PDFNum($self->data()->{'fontweight'})
        if defined $self->data()->{'fontweight'};
    $descriptor->{'FontStretch'}  = PDFName($self->data()->{'fontstretch'})
        if defined $self->data()->{'fontstretch'};

    return $descriptor;
}

sub tounicodemap {
    my $self = shift();

    return $self if defined $self->{'ToUnicode'};

    my $stream = qq|\%\% Custom\n\%\% CMap\n\%\%\n/CIDInit /ProcSet findresource begin\n|;
    $stream .= qq|12 dict begin begincmap\n|;
    $stream .= qq|/CIDSystemInfo <<\n|;
    $stream .= sprintf(qq|   /Registry (%s)\n|, $self->name());
    $stream .= qq|   /Ordering (XYZ)\n|;
    $stream .= qq|   /Supplement 0\n|;
    $stream .= qq|>> def\n|;
    $stream .= sprintf(qq|/CMapName /pdfbldr-%s+0 def\n|, $self->name());
    if ($self->can('uniByCId') and $self->can('glyphNum')) {
        # this is a type0 font
        $stream .= sprintf(qq|1 begincodespacerange <0000> <%04X> endcodespacerange\n|, $self->glyphNum() - 1);
        for (my $j = 0; $j < $self->glyphNum(); $j++) {
            my $i = $self->glyphNum() - $j > 100 ? 100 : $self->glyphNum() - $j;
            if      ($j == 0) {
                $stream .= qq|$i beginbfrange\n|;
            } elsif ($j % 100 == 0) {
                $stream .= qq|endbfrange\n|;
                $stream .= qq|$i beginbfrange\n|;
            }
            # Default to 0000 if uniByCId returns undef in order to match
            # previous behavior minus an uninitialized value warning.  It's
            # worth looking into what should be happening here, since this may
            # not be the correct behavior.
            $stream .= sprintf(qq|<%04x> <%04x> <%04x>\n|, $j, $j, ($self->uniByCId($j) // 0));
        }
        $stream .= "endbfrange\n";
    } else {
        # everything else is single byte font
        $stream .= qq|1 begincodespacerange\n<00> <FF>\nendcodespacerange\n|;
        $stream .= qq|256 beginbfchar\n|;
        for (my $j=0; $j < 256; $j++) {
            $stream .= sprintf(qq|<%02X> <%04X>\n|, $j, $self->uniByEnc($j));
        }
        $stream .= qq|endbfchar\n|;
    }
    $stream .= qq|endcmap CMapName currendict /CMap defineresource pop end end\n|;

    my $cmap = PDFDict();
    $cmap->{'Type'}                          = PDFName('CMap');
    $cmap->{'CMapName'}                      = PDFName(sprintf(qq|pdfbldr-%s+0|, $self->name()));
    $cmap->{'CIDSystemInfo'}                 = PDFDict();
    $cmap->{'CIDSystemInfo'}->{'Registry'}   = PDFString($self->name(), 'x');
    $cmap->{'CIDSystemInfo'}->{'Ordering'}   = PDFString('XYZ', 'x');
    $cmap->{'CIDSystemInfo'}->{'Supplement'} = PDFNum(0);

    $self->{' apipdf'}->new_obj($cmap);
    $cmap->{' nofilt'}                       = 1;
    $cmap->{' stream'}                       = Compress::Zlib::compress($stream);
    $cmap->{'Filter'}                        = PDFArray(PDFName('FlateDecode'));
    $self->{'ToUnicode'}                     = $cmap;

    return $self;
}

=head1 FONT-MANAGEMENT RELATED METHODS

=head2 fontname

    $name = $font->fontname()

=over

Return the font's name (a.k.a. display name).

=back

=cut

sub fontname { 
    return $_[0]->data()->{'fontname'}; 
}

=head2 altname

    $name = $font->altname()

=over

Return the font's alternative name (a.k.a. Windows name for a PostScript font).

=back

=cut

sub altname { 
    return $_[0]->data()->{'altname'}; 
}

=head2 subname

    $name = $font->subname()

=over

Return the font's subname (a.k.a. font variant).

=back

=cut

sub subname { 
    return $_[0]->data()->{'subname'}; 
}

=head2 apiname

    $name = $font->apiname()

=over

Return the font's name to be used internally (should be equal to $font->name()).

=back

=cut

sub apiname { 
    return $_[0]->data()->{'apiname'}; 
}

=head2 issymbol

    $issymbol = $font->issymbol()

=over

Return the font's symbol flag (i.e., is this a symbol font).

=back

=cut

sub issymbol { 
    return $_[0]->data()->{'issymbol'}; 
}

=head2 iscff

    $iscff = $font->iscff()

=over

Return the font's Compact Font Format flag.

=back

=cut

sub iscff { 
    return $_[0]->data()->{'iscff'}; 
}

=head1 TYPOGRAPHY-RELATED METHODS

=head2 fontbbox

    ($llx,$lly, $urx,$ury) = $font->fontbbox()

=over

Return the font's bounding box.

=back

=cut

sub fontbbox { 
    my @bbox = @{$_[0]->data()->{'fontbbox'}}; 
    # rearrange to LL UR order
    if ($bbox[0] > $bbox[2]) {
	@bbox = ($bbox[2], $bbox[3], $bbox[0], $bbox[1]);
    }
    return @bbox;
}

=head2 capheight

    $capheight = $font->capheight()

=over

Return the font's capheight value.

=back

=cut

sub capheight { 
    return $_[0]->data()->{'capheight'}; 
}

=head2 xheight

    $xheight = $font->xheight()

=over

Return the font's xheight value.

=back

=cut

sub xheight { 
    return $_[0]->data()->{'xheight'}; 
}

=head2 missingwidth

    $missingwidth = $font->missingwidth()

=over

Return the font's missingwidth value.

=back

=cut

sub missingwidth { 
    return $_[0]->data()->{'missingwidth'}; 
}

=head2 maxwidth

    $maxwidth = $font->maxwidth()

=over

Return the font's maxwidth value.

=back

=cut

sub maxwidth { 
    return $_[0]->data()->{'maxwidth'}; 
}

=head2 avgwidth

    $avgwidth = $font->avgwidth()

=over

Return the font's avgwidth (average width) value.

=back

=cut

sub avgwidth {
    my ($self) = @_;

    my $aw = $self->data()->{'avgwidth'};
    $aw ||= ((
	# numbers are character-frequency weighting counts
	# presumably for English text... ? it may be a little off for
	# other languages
        $self->wxByGlyph('a')*64  +
        $self->wxByGlyph('b')*14  +
        $self->wxByGlyph('c')*27  +
        $self->wxByGlyph('d')*35  +
        $self->wxByGlyph('e')*100 +
        $self->wxByGlyph('f')*20  +
        $self->wxByGlyph('g')*14  +
        $self->wxByGlyph('h')*42  +
        $self->wxByGlyph('i')*63  +
        $self->wxByGlyph('j')* 3  +
        $self->wxByGlyph('k')* 6  +
        $self->wxByGlyph('l')*35  +
        $self->wxByGlyph('m')*20  +
        $self->wxByGlyph('n')*56  +
        $self->wxByGlyph('o')*56  +
        $self->wxByGlyph('p')*17  +
        $self->wxByGlyph('q')* 4  +
        $self->wxByGlyph('r')*49  +
        $self->wxByGlyph('s')*56  +
        $self->wxByGlyph('t')*71  +
        $self->wxByGlyph('u')*31  +
        $self->wxByGlyph('v')*10  +
        $self->wxByGlyph('w')*18  +
        $self->wxByGlyph('x')* 3  +
        $self->wxByGlyph('y')*18  +
        $self->wxByGlyph('z')* 2  +
        $self->wxByGlyph('A')*64  +
        $self->wxByGlyph('B')*14  +
        $self->wxByGlyph('C')*27  +
        $self->wxByGlyph('D')*35  +
        $self->wxByGlyph('E')*100 +
        $self->wxByGlyph('F')*20  +
        $self->wxByGlyph('G')*14  +
        $self->wxByGlyph('H')*42  +
        $self->wxByGlyph('I')*63  +
        $self->wxByGlyph('J')* 3  +
        $self->wxByGlyph('K')* 6  +
        $self->wxByGlyph('L')*35  +
        $self->wxByGlyph('M')*20  +
        $self->wxByGlyph('N')*56  +
        $self->wxByGlyph('O')*56  +
        $self->wxByGlyph('P')*17  +
        $self->wxByGlyph('Q')* 4  +
        $self->wxByGlyph('R')*49  +
        $self->wxByGlyph('S')*56  +
        $self->wxByGlyph('T')*71  +
        $self->wxByGlyph('U')*31  +
        $self->wxByGlyph('V')*10  +
        $self->wxByGlyph('W')*18  +
        $self->wxByGlyph('X')* 3  +
        $self->wxByGlyph('Y')*18  +
        $self->wxByGlyph('Z')* 2  +
        $self->wxByGlyph('space')*332
    ) / 2000);

    return int($aw);
}

=head2 flags

    $flags = $font->flags()

=over

Return the font's flags value.

=back

=cut

sub flags { 
    return $_[0]->data()->{'flags'}; 
}

=head2 stemv

    $stemv = $font->stemv()

=over

Return the font's stemv value.

=back

=cut

sub stemv { 
    return $_[0]->data()->{'stemv'}; 
}

=head2 stemh

    $stemh = $font->stemh()

=over

Return the font's stemh value.

=back

=cut

sub stemh { 
    return $_[0]->data()->{'stemh'}; 
}

=head2 italicangle

    $italicangle = $font->italicangle()

=over

Return the font's italicangle (slant, obliqueness) value.

=back

=cut

sub italicangle { 
    return $_[0]->data()->{'italicangle'}; 
}

=head2 isfixedpitch

    $isfixedpitch = $font->isfixedpitch()

=over

Return the font's isfixedpitch flag.

=back

=cut

sub isfixedpitch { 
    return $_[0]->data()->{'isfixedpitch'}; 
}

=head2 underlineposition

    $underlineposition = $font->underlineposition()

=over

Return the font's underlineposition value.

=back

=cut

sub underlineposition { 
    return $_[0]->data()->{'underlineposition'}; 
}

=head2 underlinethickness

    $underlinethickness = $font->underlinethickness()

=over

Return the font's underlinethickness value.

=back

=cut

sub underlinethickness { 
    return $_[0]->data()->{'underlinethickness'}; 
}

=head2 ascender

    $ascender = $font->ascender()

=over

Return the font's ascender value.

=back

=cut

sub ascender { 
    return $_[0]->data()->{'ascender'}; 
}

=head2 descender

    $descender = $font->descender()

=over

Return the font's descender value.

=back

=cut

sub descender { 
    return $_[0]->data()->{'descender'}; 
}

=head1 GLYPH-RELATED METHODS

=head2 glyphNames

    @names = $font->glyphNames()

=over

Return the defined glyph names of the font.

=back

=cut

sub glyphNames { 
    return keys %{$_[0]->data()->{'wx'}}; 
}

=head2 glyphNum

    $glNum = $font->glyphNum()

=over

Return the number of defined glyph names of the font.

=back

=cut

sub glyphNum { 
   #my $self = shift();
   #return scalar $self->glyphNames();
    return scalar keys %{$_[0]->data()->{'wx'}}; 
}

=head2 uniByGlyph

    $uni = $font->uniByGlyph($char)

=over

Return the unicode by glyph name.

=back

=cut

sub uniByGlyph { 
   #my ($self, $name) = @_;
   #return $self->data()->{'n2u'}->{$name};
    return $_[0]->data()->{'n2u'}->{$_[1]}; 
}

=head2 uniByEnc

    $uni = $font->uniByEnc($char)

=over

Return the Unicode by the font's encoding map.

=back

=cut

sub uniByEnc { 
    my ($self, $enc) = @_;
    my $uni = $self->data()->{'e2u'}->[$enc]; 
    # fallback to U+0000 if no match
    $uni = 0 unless defined $uni;
    return $uni;
}

=head2 uniByMap

    $uni = $font->uniByMap($char)

=over

Return the Unicode by the font's default map.

=back

=cut

sub uniByMap { 
    return $_[0]->data()->{'uni'}->[$_[1]]; 
}

=head2 encByGlyph

    $char = $font->encByGlyph($glyph)

=over

Return the character by the given glyph name of the font's encoding map.

=back

=cut

sub encByGlyph { 
    return $_[0]->data()->{'n2e'}->{$_[1]} || 0; 
}

=head2 encByUni

    $char = $font->encByUni($uni)

=over

Return the character by the given Unicode of the font's encoding map.

=back

=cut

sub encByUni { 
    return $_[0]->data()->{'u2e'}->{$_[1]} || 
           $_[0]->data()->{'u2c'}->{$_[1]} || 
	   0; 
}

=head2 mapByGlyph

    $char = $font->mapByGlyph($glyph)

=over

Return the character by the given glyph name of the font's default map.

=back

=cut

sub mapByGlyph { 
    return $_[0]->data()->{'n2c'}->{$_[1]} || 0; 
}

=head2 mapByUni

    $char = $font->mapByUni($uni)

=over

Return the character by the given Unicode of the font's default map.

=back

=cut

sub mapByUni { 
    return $_[0]->data()->{'u2c'}->{$_[1]} || 0; 
}

=head2 glyphByUni

    $name = $font->glyphByUni($unicode)

=over

Return the glyph's name by the font's Unicode map.
B<CAUTION:> non-standard glyph-names are mapped onto
the ms-symbol area (0xF000).

=back

=cut

sub glyphByUni { 
    return $_[0]->data()->{'u2n'}->{$_[1]} || '.notdef'; 
}

=head2 glyphByEnc

    $name = $font->glyphByEnc($char)

=over

Return the glyph's name by the font's encoding map.

=back

=cut

sub glyphByEnc {
    return $_[0]->data()->{'e2n'}->[$_[1]];
}

=head2 glyphByMap

    $name = $font->glyphByMap($char)

=over

Return the glyph's name by the font's default map.

=back

=cut

sub glyphByMap { 
    return $_[0]->data()->{'char'}->[$_[1]]; 
}

=head2 wxByGlyph

    $width = $font->wxByGlyph($glyph)

=over

Return the glyph's width.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

=back

=cut

sub wxByGlyph {
    my ($self, $glyph) = @_;

    my $width;
    if (ref($self->data()->{'wx'}) eq 'HASH') {
    	$width   = $self->data()->{'wx'}->{$glyph} if defined $glyph;
    } else {
    	my $cid = $self->cidByUni(uniByName($glyph));
    	$width = $self->data()->{'wx'}->[$cid] if defined $cid;
    }
    $width //= $self->missingwidth();
    $width //= 300;

    return $width;
}

=head2 wxByUni

    $width = $font->wxByUni($uni)

=over

Return the Unicode character's width.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

=back

=cut

sub wxByUni {
    my ($self, $uni) = @_;
    my ($gid, $width);

    $gid = $self->glyphByUni($uni) if defined $uni;
    $width = $self->data()->{'wx'}->{$gid} if defined $gid;
    $width //= $self->missingwidth();
    $width //= 300;

    return $width;
}

=head2 wxByEnc

    $width = $font->wxByEnc($char)

=over

Return the character's width based on the current encoding.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

=back

=cut

sub wxByEnc {
    my ($self, $char) = @_;

    my $glyph;
    $glyph = $self->glyphByEnc($char) if defined $char;
    my $width;
    $width = $self->data()->{'wx'}->{$glyph} if defined $glyph;

    $width //= $self->missingwidth();
    $width //= 300;

    return $width;
}

=head2 wxMissingByEnc

    $flag = $font->wxMissingByEnc($char)

=over

Return true if the character's width (based on the current encoding) is
supplied by "missing width" of font.

=back

=cut

sub wxMissingByEnc {
    my ($self, $char) = @_;

    my $glyph = $self->glyphByEnc($char);
    my $width = $self->data()->{'wx'}->{$glyph};

    return !defined($width);
}

=head2 wxByMap

    $width = $font->wxByMap($char)

=over

Return the character's width based on the font's default encoding.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

=back

=cut

sub wxByMap {
    my ($self, $char) = @_;

    my $glyph;
    $glyph = $self->glyphByMap($char) if defined $char;
    my $width;
    $width = $self->data()->{'wx'}->{$glyph} if defined $glyph;
    $width //= $self->missingwidth();
    $width //= 300;

    return $width;
}

=head2 width

    $wd = $font->width($text)

=over

Return the width of $text as if it were at font size 1 (unscaled).
B<CAUTION:> works correctly only if a proper Perl string
is used, either in native or UTF-8 format (check utf8-flag).

=back

=cut

sub width {
    my ($self, $text) = @_;

    $text = $self->strByUtf($text) if utf8::is_utf8($text);

    my @cache;
    my $width = 0;
    my $kern = $self->{'-dokern'} && ref($self->data()->{'kern'});
    my $last_glyph = '';
    foreach my $n (unpack('C*',$text)) {
        $cache[$n] //= $self->wxByEnc($n);
        $width += $cache[$n];
        if ($kern) {
            my $glyph = $self->data()->{'e2n'}->[$n];
            $width += ($self->data()->{'kern'}->{$last_glyph . ':' . $glyph} // 0);
            $last_glyph = $glyph;
        }
    }
    $width /= 1000;
    return $width;
}

=head2 width_array

    @widths = $font->width_array($text)

=over

Return (as an array) the widths of the words in $text as if they were at size 1.

=back

=cut

sub width_array {
    my ($self, $text) = @_;

    $text = $self->utfByStr($text) unless utf8::is_utf8($text);
    my @widths = map { $self->width($_) } split(/\s+/, $text);
    return @widths;
}

=head2 utfByStr

    $utf8string = $font->utfByStr($string)

=over

Return the utf8-string from string based on the font's encoding map.

=back

=cut

sub utfByStr {
    my ($self, $string) = @_;

    $string = pack('U*', map { $self->uniByEnc($_) } unpack('C*', $string));
    utf8::upgrade($string);
    return $string;
}

=head2 strByUtf

    $string = $font->strByUtf($utf8_string)

=over

Return the encoded string from utf8-string based on the font's encoding map.

=back

=cut

sub strByUtf {
    my ($self, $utf8_string) = @_;

    $utf8_string = pack('C*', map { $self->encByUni($_) & 0xFF } unpack('U*', $utf8_string));
    utf8::downgrade($utf8_string);
    return $utf8_string;
}

=head2 textByStr

    $pdf_string = $font->textByStr($string)

=over

Return a properly formatted representation of $string for use in the PDF.

=back

=cut

sub textByStr {
    my ($self, $string) = @_;

    if (not defined $string) { $string = ''; }
    $string = $self->strByUtf($string) if utf8::is_utf8($string);
    my $text = $string;
    $text =~ s/\\/\\\\/go;
    $text =~ s/([\x00-\x1f])/sprintf('\%03lo',ord($1))/ge;
    $text =~ s/([\{\}\[\]\(\)])/\\$1/g;

    return $text;
}

=head2 textByStrKern

    $pdf_string = $font->textByStrKern($string)

=over

Return a properly formatted representation of $string, with kerning, 
for use in the PDF.

=back

=cut

sub textByStrKern {
    my ($self, $string) = @_;

    return '(' . $self->textByStr($string) . ')' unless $self->{'-dokern'} && ref($self->data()->{'kern'});
    $string = $self->strByUtf($string) if utf8::is_utf8($string);

    my $text = ' ';
    my $tBefore = 0;
    my $last_glyph = '';

    foreach my $n (unpack('C*', $string)) {
        my $glyph = $self->data()->{'e2n'}->[$n];
        if (defined $self->data()->{'kern'}->{$last_glyph . ':' . $glyph}) {
            $text .= ') ' if $tBefore;
            $text .= sprintf('%i ', -($self->data()->{'kern'}->{$last_glyph . ':' . $glyph}));
            $tBefore = 0;
        }
        $last_glyph = $glyph;
        my $t = pack('C', $n);
        $t =~ s/\\/\\\\/go;
        $t =~ s/([\x00-\x1f])/sprintf('\%03lo',ord($1))/ge;
        $t =~ s/([\{\}\[\]\(\)])/\\$1/g;
        $text .= '(' unless $tBefore;
        $text .= "$t";
        $tBefore = 1;
    }
    $text .= ') ' if $tBefore;
    return $text;
}

# Maintainer's note: $size here is used solely as a flag to determine whether or
# not to append a text-showing operator (TJ or Tj).
sub text {
    my ($self, $string, $size, $indent) = @_;
    if (not defined $string) { $string = ''; }
    my $text = $self->textByStr($string);

    if      (defined $size && $self->{'-dokern'}) {
        $text = $self->textByStrKern($string);
	return "[ $indent $text ] TJ" if $indent;
	return "[ $text ] TJ";
    } elsif (defined $size) {
	return "[ $indent ($text) ] TJ" if $indent;
	return "($text) Tj";
    } else {
	# will need a later Tj operator to actually see this!
        return "($text)";
    }
}

sub isvirtual { 
    return; 
}

1;
