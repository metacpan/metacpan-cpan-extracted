package PDF::Builder::Resource::CIDFont;

use base 'PDF::Builder::Resource::BaseFont';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use Encode qw(:all);

use PDF::Builder::Basic::PDF::Utils;
use PDF::Builder::Util;

=head1 NAME

PDF::Builder::Resource::CIDFont - Base class for CID fonts

Inherits from L<PDF::Builder::Resource::BaseFont>

=head1 METHODS

=head2 new

    $font = PDF::Builder::Resource::CIDFont->new($pdf, $name)

=over

Returns a cid-font object, base class for all CID-based fonts.

=back

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

=head2 cidsByStr

    $cidstring = $font->cidsByStr($string)

=over

Returns the cid-string from string based on the font's encoding map.

=back

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

=head2 cidsByUtf

    $cidstring = $font->cidsByUtf($utf8string)

=over

Returns the CID-encoded string from utf8-string.

=back

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

    # need to break up $text into fragments ending with x20
    # TBD: handle other spaces (espec. xA0) "appropriately" (control by flag)
    #      0 = x20 space only
    #      1 (default) = x20 and same/longer spaces
    #      2 = all spaces
    #      the problem is, other font types handle only x20 in Reader
    my ($latest_page, $wordspace, $fontsize);
    $latest_page = $self->{' apipdf'}->{' outlist'}[0]->{'Pages'}->{'Kids'}->{' val'}[-1];
    $wordspace = $latest_page->{'Contents'}->{' val'}->[1]->{' wordspace'};
    $fontsize = $latest_page->{'Contents'}->{' val'}->[1]->{' fontsize'};
if (!defined $wordspace || !defined $fontsize || $fontsize <= 0) {
    $wordspace = $latest_page->{'Contents'}->{' val'}->[0]->{' wordspace'};
    $fontsize = $latest_page->{'Contents'}->{' val'}->[0]->{' fontsize'};
}
    my @fragments = ( $text ); # default for wordspace = 0
    # TBD: get list of different lengths of spaces found, split on all of them
    #      could have null fragments where two or more spaces in a row, or
    #        text ended with a space
    if ($wordspace) {
	# split appears to drop trailing blanks, so need a guard
        @fragments = split / /, $text."|";
	chop($fragments[-1]);
    }

    my $out_str = '';
    for (my $i = 0; $i <= $#fragments; $i++) {
	if ($fragments[$i] ne '') {
            my $newtext = $self->textByStr($fragments[$i]);  # '<glyphIDsList>'
            if      (defined $size && $self->{'-dokern'}) {
                $newtext = $self->textByStrKern($fragments[$i], $size, $indent);
                $out_str .= $newtext;
            } elsif (defined $size) {
                if (defined($indent) && $indent!=0) {
	            $out_str .= "[ $indent $newtext ] TJ";
                } else {
	            $out_str .= "$newtext Tj";
                }
            } else {
                $out_str .= $newtext;
            }
	}
	# unless this is the last fragment (no space follows), add a "kerned"
	# space to out_str (reduce its effective width by moving left).
	# TBD: different spaces of different lengths with different "kerns"
	if ($i < $#fragments) {
	    $out_str .= "[ ".$self->textByStrKern(' ')." ".(-$wordspace/$fontsize*1000)." ] TJ";
	}
    }
    return $out_str;
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

1;
