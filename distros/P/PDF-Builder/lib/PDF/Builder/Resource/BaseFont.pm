package PDF::Builder::Resource::BaseFont;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.019'; # VERSION
my $LAST_UPDATE = '3.018'; # manually update whenever code is changed

use Compress::Zlib;
use Encode qw(:all);
use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::BaseFont - Base class for font resources

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::BaseFont->new($pdf, $name)

Return a font resource object.

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

=item $descriptor = $font->descrByData()

Return the font's FontDescriptor key structure based on the font's data.

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

=back

=head1 FONT-MANAGEMENT RELATED METHODS

=over

=item $name = $font->fontname()

Return the font's name (a.k.a. display name).

=cut

sub fontname { 
    return $_[0]->data()->{'fontname'}; 
}

=item $name = $font->altname()

Return the font's alternative name (a.k.a. Windows name for a PostScript font).

=cut

sub altname { 
    return $_[0]->data()->{'altname'}; 
}

=item $name = $font->subname()

Return the font's subname (a.k.a. font variant).

=cut

sub subname { 
    return $_[0]->data()->{'subname'}; 
}

=item $name = $font->apiname()

Return the font's name to be used internally (should be equal to $font->name()).

=cut

sub apiname { 
    return $_[0]->data()->{'apiname'}; 
}

=item $issymbol = $font->issymbol()

Return the font's symbol flag (i.e., is this a symbol font).

=cut

sub issymbol { 
    return $_[0]->data()->{'issymbol'}; 
}

=item $iscff = $font->iscff()

Return the font's Compact Font Format flag.

=cut

sub iscff { 
    return $_[0]->data()->{'iscff'}; 
}

=back

=head1 TYPOGRAPHY-RELATED METHODS

=over

=item ($llx,$lly, $urx,$ury) = $font->fontbbox()

Return the font's bounding box.

=cut

sub fontbbox { 
    my @bbox = @{$_[0]->data()->{'fontbbox'}}; 
    # rearrange to LL UR order
    if ($bbox[0] > $bbox[2]) {
	@bbox = ($bbox[2], $bbox[3], $bbox[0], $bbox[1]);
    }
    return @bbox;
}

=item $capheight = $font->capheight()

Return the font's capheight value.

=cut

sub capheight { 
    return $_[0]->data()->{'capheight'}; 
}

=item $xheight = $font->xheight()

Return the font's xheight value.

=cut

sub xheight { 
    return $_[0]->data()->{'xheight'}; 
}

=item $missingwidth = $font->missingwidth()

Return the font's missingwidth value.

=cut

sub missingwidth { 
    return $_[0]->data()->{'missingwidth'}; 
}

=item $maxwidth = $font->maxwidth()

Return the font's maxwidth value.

=cut

sub maxwidth { 
    return $_[0]->data()->{'maxwidth'}; 
}

=item $avgwidth = $font->avgwidth()

Return the font's avgwidth (average width) value.

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

=item $flags = $font->flags()

Return the font's flags value.

=cut

sub flags { 
    return $_[0]->data()->{'flags'}; 
}

=item $stemv = $font->stemv()

Return the font's stemv value.

=cut

sub stemv { 
    return $_[0]->data()->{'stemv'}; 
}

=item $stemh = $font->stemh()

Return the font's stemh value.

=cut

sub stemh { 
    return $_[0]->data()->{'stemh'}; 
}

=item $italicangle = $font->italicangle()

Return the font's italicangle value.

=cut

sub italicangle { 
    return $_[0]->data()->{'italicangle'}; 
}

=item $isfixedpitch = $font->isfixedpitch()

Return the font's isfixedpitch flag.

=cut

sub isfixedpitch { 
    return $_[0]->data()->{'isfixedpitch'}; 
}

=item $underlineposition = $font->underlineposition()

Return the font's underlineposition value.

=cut

sub underlineposition { 
    return $_[0]->data()->{'underlineposition'}; 
}

=item $underlinethickness = $font->underlinethickness()

Return the font's underlinethickness value.

=cut

sub underlinethickness { 
    return $_[0]->data()->{'underlinethickness'}; 
}

=item $ascender = $font->ascender()

Return the font's ascender value.

=cut

sub ascender { 
    return $_[0]->data()->{'ascender'}; 
}

=item $descender = $font->descender()

Return the font's descender value.

=cut

sub descender { 
    return $_[0]->data()->{'descender'}; 
}

=back

=head1 GLYPH-RELATED METHODS

=over 4

=item @names = $font->glyphNames()

Return the defined glyph names of the font.

=cut

sub glyphNames { 
    return keys %{$_[0]->data()->{'wx'}}; 
}

=item $glNum = $font->glyphNum()

Return the number of defined glyph names of the font.

=cut

sub glyphNum { 
   #my $self = shift();
   #return scalar $self->glyphNames();
    return scalar keys %{$_[0]->data()->{'wx'}}; 
}

=item $uni = $font->uniByGlyph($char)

Return the unicode by glyph name.

=cut

sub uniByGlyph { 
   #my ($self, $name) = @_;
   #return $self->data()->{'n2u'}->{$name};
    return $_[0]->data()->{'n2u'}->{$_[1]}; 
}

=item $uni = $font->uniByEnc($char)

Return the Unicode by the font's encoding map.

=cut

sub uniByEnc { 
    my ($self, $enc) = @_;
    my $uni = $self->data()->{'e2u'}->[$enc]; 
    # fallback to U+0000 if no match
    $uni = 0 unless defined $uni;
    return $uni;
}

=item $uni = $font->uniByMap($char)

Return the Unicode by the font's default map.

=cut

sub uniByMap { 
    return $_[0]->data()->{'uni'}->[$_[1]]; 
}

=item $char = $font->encByGlyph($glyph)

Return the character by the given glyph name of the font's encoding map.

=cut

sub encByGlyph { 
    return $_[0]->data()->{'n2e'}->{$_[1]} || 0; 
}

=item $char = $font->encByUni($uni)

Return the character by the given Unicode of the font's encoding map.

=cut

sub encByUni { 
    return $_[0]->data()->{'u2e'}->{$_[1]} || 
           $_[0]->data()->{'u2c'}->{$_[1]} || 
	   0; 
}

=item $char = $font->mapByGlyph($glyph)

Return the character by the given glyph name of the font's default map.

=cut

sub mapByGlyph { 
    return $_[0]->data()->{'n2c'}->{$_[1]} || 0; 
}

=item $char = $font->mapByUni($uni)

Return the character by the given Unicode of the font's default map.

=cut

sub mapByUni { 
    return $_[0]->data()->{'u2c'}->{$_[1]} || 0; 
}

=item $name = $font->glyphByUni($unicode)

Return the glyph's name by the font's Unicode map.
B<BEWARE:> non-standard glyph-names are mapped onto
the ms-symbol area (0xF000).

=cut

sub glyphByUni { 
    return $_[0]->data()->{'u2n'}->{$_[1]} || '.notdef'; 
}

=item $name = $font->glyphByEnc($char)

Return the glyph's name by the font's encoding map.

=cut

sub glyphByEnc {
    return $_[0]->data()->{'e2n'}->[$_[1]];
}

=item $name = $font->glyphByMap($char)

Return the glyph's name by the font's default map.

=cut

sub glyphByMap { 
    return $_[0]->data()->{'char'}->[$_[1]]; 
}

=item $width = $font->wxByGlyph($glyph)

Return the glyph's width.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

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

=item $width = $font->wxByUni($uni)

Return the Unicode character's width.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

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

=item $width = $font->wxByEnc($char)

Return the character's width based on the current encoding.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

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

=item $flag = $font->wxMissingByEnc($char)

Return true if the character's width (based on the current encoding) is
supplied by "missing width" of font.

=cut

sub wxMissingByEnc {
    my ($self, $char) = @_;

    my $glyph = $self->glyphByEnc($char);
    my $width = $self->data()->{'wx'}->{$glyph};

    return !defined($width);
}

=item $width = $font->wxByMap($char)

Return the character's width based on the font's default encoding.
This is a value, that when divided by 1000 and multiplied by
the font size (height in points), gives the advance width to the
next character's start. Typically, the width will be under 1000.

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

=item $wd = $font->width($text)

Return the width of $text as if it were at size 1.
B<BEWARE:> works only correctly if a proper Perl string
is used, either in native or UTF-8 format (check utf8-flag).

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

=item @widths = $font->width_array($text)

Return (as an array) the widths of the words in $text as if they were at size 1.

=cut

sub width_array {
    my ($self, $text) = @_;

    $text = $self->utfByStr($text) unless utf8::is_utf8($text);
    my @widths = map { $self->width($_) } split(/\s+/, $text);
    return @widths;
}

=back

=head1 STRING METHODS

=over

=item $utf8string = $font->utfByStr($string)

Return the utf8-string from string based on the font's encoding map.

=cut

sub utfByStr {
    my ($self, $string) = @_;

    $string = pack('U*', map { $self->uniByEnc($_) } unpack('C*', $string));
    utf8::upgrade($string);
    return $string;
}

=item $string = $font->strByUtf($utf8_string)

Return the encoded string from utf8-string based on the font's encoding map.

=cut

sub strByUtf {
    my ($self, $utf8_string) = @_;

    $utf8_string = pack('C*', map { $self->encByUni($_) & 0xFF } unpack('U*', $utf8_string));
    utf8::downgrade($utf8_string);
    return $utf8_string;
}

=item $pdf_string = $font->textByStr($string)

Return a properly formatted representation of $string for use in the PDF.

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

=item $pdf_string = $font->textByStrKern($string)

Return a properly formatted representation of $string, with kerning, 
for use in the PDF.

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

=back

=cut

1;
