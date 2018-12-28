package PDF::Builder::Resource::CIDFont;

use base 'PDF::Builder::Resource::BaseFont';

use strict;
no warnings qw[ deprecated recursion uninitialized ];

our $VERSION = '3.013'; # VERSION
my $LAST_UPDATE = '3.013'; # manually update whenever code is changed

use Encode qw(:all);

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::CIDFont - Base class for CID fonts

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::CIDFont->new($pdf, $name)

Returns a cid-font object, base class for all CID-based fonts.

=cut

sub new {
    my ($class, $pdf, $name, @opts) = @_;

    my %opts = ();
    %opts = @opts if (scalar @opts)%2 == 0;

    $class = ref $class if ref $class;
    my $self = $class->SUPER::new($pdf, $name);
    $pdf->new_obj($self) if defined($pdf) && !$self->is_obj($pdf);

    $self->{'Type'} = PDFName('Font');
    $self->{'Subtype'} = PDFName('Type0');
    $self->{'Encoding'} = PDFName('Identity-H');

    my $de = PDFDict();
    $pdf->new_obj($de);
    $self->{'DescendantFonts'} = PDFArray($de);

    $de->{'Type'} = PDFName('Font');
    $de->{'CIDSystemInfo'} = PDFDict();
    $de->{'CIDSystemInfo'}->{'Registry'} = PDFString('Adobe', 'x');
    $de->{'CIDSystemInfo'}->{'Ordering'} = PDFString('Identity', 'x');
    $de->{'CIDSystemInfo'}->{'Supplement'} = PDFNum(0);
    $de->{'CIDToGIDMap'} = PDFName('Identity');

    $self->{' de'} = $de;

    return $self;
}

sub glyphByCId { 
    return $_[0]->data()->{'g2n'}->[$_[1]]; 
}

sub uniByCId { 
    return $_[0]->data()->{'g2u'}->[$_[1]]; 
}

sub cidByUni { 
    return $_[0]->data()->{'u2g'}->{$_[1]}; 
}

sub cidByEnc { 
    return $_[0]->data()->{'e2g'}->[$_[1]]; 
}

sub wxByCId {
    my $self = shift;
    my $g = shift;

    my $w;

    if      (ref($self->data()->{'wx'}) eq 'ARRAY' && 
	     defined $self->data()->{'wx'}->[$g]) {
        $w = int($self->data()->{'wx'}->[$g]);
    } elsif (ref($self->data()->{'wx'}) eq 'HASH' && 
	     defined $self->data()->{'wx'}->{$g}) {
        $w = int($self->data()->{'wx'}->{$g});
    } else {
        $w = $self->missingwidth();
    }

    return $w;
}

sub wxByUni { 
    return $_[0]->wxByCId($_[0]->data()->{'u2g'}->{$_[1]}); 
}

sub wxByEnc { 
    return $_[0]->wxByCId($_[0]->data()->{'e2g'}->[$_[1]]); 
}

sub width {
    my ($self, $text) = @_;

    return $self->width_cid($self->cidsByStr($text));
}

sub width_cid {
    my ($self, $text) = @_;

    my $width = 0;
    my $lastglyph = 0;
    foreach my $n (unpack('n*', $text)) {
        $width += $self->wxByCId($n);
        if ($self->{'-dokern'} && $self->haveKernPairs()) {
            if ($self->kernPairCid($lastglyph, $n)) {
                $width -= $self->kernPairCid($lastglyph, $n);
            }
        }
        $lastglyph = $n;
    }
    $width /= 1000;
    return $width;
}

=item $cidstring = $font->cidsByStr($string)

Returns the cid-string from string based on the font's encoding map.

=cut

sub _cidsByStr {
    my ($self, $s) = @_;

    $s = pack('n*', map { $self->cidByEnc($_) } unpack('C*', $s));
    return $s;
}

sub cidsByStr {
    my ($self, $text) = @_;

    if      (is_utf8($text) && 
	    defined $self->data()->{'decode'} && 
	    $self->data()->{'decode'} ne 'ident') {
        $text = encode($self->data()->{'decode'}, $text);
    } elsif (is_utf8($text) && $self->data()->{'decode'} eq 'ident') {
        $text = $self->cidsByUtf($text);
    } elsif (!is_utf8($text) && 
	    defined $self->data()->{'encode'} && 
	    $self->data()->{'decode'} eq 'ident') {
        $text = $self->cidsByUtf(decode($self->data()->{'encode'}, $text));
    } elsif (!is_utf8($text) && 
	    $self->can('issymbol') && 
	    $self->issymbol() && 
	    $self->data()->{'decode'} eq 'ident') {
        $text = pack('U*', (map { $_+0xf000 } unpack('C*', $text)));
        $text = $self->cidsByUtf($text);
    } else {
        $text = $self->_cidsByStr($text);
    }
    return $text;
}

=item $cidstring = $font->cidsByUtf($utf8string)

Returns the CID-encoded string from utf8-string.

=cut

sub cidsByUtf {
    my ($self, $s) = @_;

    $s = pack('n*', map { $self->cidByUni($_) } (map { $_>0x7f && $_<0xA0? uniByName(nameByUni($_)): $_ } unpack('U*', $s)));
    utf8::downgrade($s);
    return $s;
}

sub textByStr {
    my ($self, $text) =  @_;

    return $self->text_cid($self->cidsByStr($text));
}

sub textByStrKern {
    my ($self, $text, $size, $indent) = @_;

    return $self->text_cid_kern($self->cidsByStr($text), $size, $indent);
}

sub text {
    my ($self, $text, $size, $indent) = @_;

    my $newtext = $self->textByStr($text);
    if      (defined $size && $self->{'-dokern'}) {
        $newtext = $self->textByStrKern($text, $size, $indent);
        return $newtext;
    } elsif (defined $size) {
        if (defined($indent) && $indent!=0) {
	    return("[ $indent $newtext ] TJ");
        } else {
	    return "$newtext Tj";
        }
    } else {
        return $newtext;
    }
}

sub text_cid {
    my ($self, $text, $size) = @_;

    if ($self->can('fontfile')) {
        foreach my $g (unpack('n*', $text)) {
            $self->fontfile()->subsetByCId($g);
        }
    }
    my $newtext = unpack('H*', $text);
    if (defined $size) {
        return "<$newtext> Tj";
    } else {
        return "<$newtext>";
    }
}

sub text_cid_kern {
    my ($self, $text, $size, $indent) = @_;

    if ($self->can('fontfile')) {
        foreach my $g (unpack('n*', $text)) {
            $self->fontfile()->subsetByCId($g);
        }
    }
    if      (defined $size && $self->{'-dokern'} && $self->haveKernPairs()) {
        my $newtext = ' ';
        my $lastglyph = 0;
        my $tBefore = 0;
        foreach my $n (unpack('n*', $text)) {
            if ($self->kernPairCid($lastglyph, $n)) {
                $newtext .= '> ' if $tBefore;
                $newtext .= sprintf('%i ', $self->kernPairCid($lastglyph, $n));
                $tBefore = 0;
            }
            $lastglyph = $n;
            my $t = sprintf('%04X', $n);
            $newtext .= '<' if !$tBefore;
            $newtext .= $t;
            $tBefore = 1;
        }
        $newtext .= '> ' if $tBefore;
        if (defined($indent) && $indent != 0) {
	    return "[ $indent $newtext ] TJ";
        } else {
            return "[ $newtext ] TJ";
        }
    } elsif (defined $size) {
        my $newtext = unpack('H*', $text);
        if (defined($indent) && $indent != 0) {
	    return "[ $indent <$newtext> ] TJ";
        } else {
	    return "<$newtext> Tj";
        }
    } else {
        my $newtext = unpack('H*', $text);
        return "<$newtext>";
    }
}

sub kernPairCid {
    return 0;
}

sub haveKernPairs {
    return 0;
}

sub encodeByName {
    my ($self, $enc) = @_;

    return if $self->issymbol();

    $self->data()->{'e2u'} = [ map { $_>0x7f && $_<0xA0? uniByName(nameByUni($_)): $_ } unpack('U*', decode($enc, pack('C*', 0..255))) ] if defined $enc;
    $self->data()->{'e2n'} = [ map { $self->data()->{'g2n'}->[$self->data()->{'u2g'}->{$_} || 0] || '.notdef' } @{$self->data()->{'e2u'}} ];
    $self->data()->{'e2g'} = [ map { $self->data()->{'u2g'}->{$_} || 0 } @{$self->data()->{'e2u'}} ];

    $self->data()->{'u2e'} = {};
    foreach my $n (reverse 0..255) {
        $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]} = $n
	    unless defined $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]};
    }

    return $self;
}

sub subsetByCId {
    return 1;
}

sub subvec {
    return 1;
}

sub glyphNum {
    my $self = shift;

    if (defined $self->data()->{'glyphs'}) {
        return $self->data()->{'glyphs'};
    }
    return scalar @{$self->data()->{'wx'}};
}

sub outobjdeep {
    my ($self, $fh, $pdf, %opts) = @_;

    return $self->SUPER::outobjdeep($fh, $pdf, %opts);
}

=back

=cut

1;
