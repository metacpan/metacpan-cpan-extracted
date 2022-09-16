package PDF::Builder::Resource::CIDFont;

use base 'PDF::Builder::Resource::BaseFont';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

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
    my ($class, $pdf, $name, %opts) = @_;

    $class = ref($class) if ref($class);
    my $self = $class->SUPER::new($pdf, $name);
    $pdf->new_obj($self) if defined($pdf) && !$self->is_obj($pdf);

    $self->{'Type'}     = PDFName('Font');
    $self->{'Subtype'}  = PDFName('Type0');
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
    my ($self, $gid) = @_;
    return $self->data()->{'g2n'}->[$gid]; 
}

sub uniByCId { 
    my ($self, $gid) = @_;
    my $uni = $self->data()->{'g2u'}->[$gid];
    # fallback to U+0000 if no match
    $uni = 0 unless defined $uni;
    return $uni;
}

# TBD note that cidByUni has been seen returning 'undef' in some cases. 
# be sure to handle this!
sub cidByUni { 
    my ($self, $gid) = @_;
    return $self->data()->{'u2g'}->{$gid}; 
}

sub cidByEnc { 
    my ($self, $gid) = @_;
    return $self->data()->{'e2g'}->[$gid]; 
}

sub wxByCId {
    my ($self, $g) = @_;

    my $w;
    my $widths = $self->data()->{'wx'};

    if      (ref($widths) eq 'ARRAY' && defined $widths->[$g]) {
        $w = int($widths->[$g]);
    } elsif (ref($widths) eq 'HASH' && defined $widths->{$g}) {
        $w = int($widths->{$g});
    } else {
        $w = $self->missingwidth();
    }

    return $w;
}

sub wxByUni { 
    my ($self, $gid) = @_;
    return $self->wxByCId($self->data()->{'u2g'}->{$gid}); 
}

sub wxByEnc { 
    my ($self, $gid) = @_;
    return $self->wxByCId($self->data()->{'e2g'}->[$gid]); 
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

    if      (utf8::is_utf8($text) && 
	    defined $self->data()->{'decode'} && 
	    $self->data()->{'decode'} ne 'ident') {
        $text = encode($self->data()->{'decode'}, $text);
    } elsif (utf8::is_utf8($text) && 
	    defined $self->data()->{'decode'} && 
	    $self->data()->{'decode'} eq 'ident') {
        $text = $self->cidsByUtf($text);
    } elsif (!utf8::is_utf8($text) && 
	    defined $self->data()->{'encode'} && 
	    defined $self->data()->{'decode'} && 
	    $self->data()->{'decode'} eq 'ident') {
        $text = $self->cidsByUtf(decode($self->data()->{'encode'}, $text));
    } elsif (!utf8::is_utf8($text) && 
	    $self->can('issymbol') && 
	    $self->issymbol() && 
	    defined $self->data()->{'decode'} && 
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

    $s = pack('n*', 
	    map { $self->cidByUni($_)||0 } 
	    (map {
		    ($_ and $_>0x7f and $_<0xA0)? uniByName(nameByUni($_)): $_ 
	    } 
	    unpack('U*', $s)));

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
    if (defined $size && $self->{'-dokern'} && $self->haveKernPairs()) {
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
            $newtext .= '<' unless $tBefore;
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
    return 0;  # PDF::API2 changed to just 'return;'
}

sub encodeByName {
    my ($self, $enc) = @_;

    return if $self->issymbol();

    if (defined $enc) {
        $self->data()->{'e2u'} = [ 
	    map { ($_ and $_>0x7f and $_<0xA0)? uniByName(nameByUni($_)): $_ } 
	    unpack('U*', decode($enc, pack('C*', 0..255)))
	];
    }
    $self->data()->{'e2n'} = [ 
	map { $self->data()->{'g2n'}->[$self->data()->{'u2g'}->{$_} || 0] || '.notdef' } 
	@{$self->data()->{'e2u'}}
    ];
    $self->data()->{'e2g'} = [ 
	map { $self->data()->{'u2g'}->{$_} || 0 } 
	@{$self->data()->{'e2u'}} 
    ];

    $self->data()->{'u2e'} = {};
    foreach my $n (reverse 0..255) {
        $self->data()->{'u2e'}->{$self->data()->{'e2u'}->[$n]} //= $n;
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

#sub outobjdeep {
#    my ($self, $fh, $pdf, %opts) = @_;
#
#    return $self->SUPER::outobjdeep($fh, $pdf, %opts);
#}

=back

=cut

1;
