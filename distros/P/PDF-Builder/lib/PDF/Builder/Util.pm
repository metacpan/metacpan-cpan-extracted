package PDF::Builder::Util;

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

# note: $a and $b are "Magic variables" according to perlcritic, and so it
# has conniptions over using them as variable names (even with "my"). so, I
# changed most of the single letter names to double letters (r,g,b -> rr,gg,bb
# etc.)

BEGIN {
    use Encode qw(:all);
    use Math::Trig;    # CAUTION: deg2rad(0) = deg2rad(360) = 0!
    use List::Util qw(min max);
    use PDF::Builder::Basic::PDF::Utils;
    use PDF::Builder::Basic::PDF::Filter;
    use PDF::Builder::Resource::Colors;
    use PDF::Builder::Resource::Glyphs;
    use PDF::Builder::Resource::PaperSizes;
    use POSIX qw( HUGE_VAL floor );

    use vars qw(
        @ISA
        @EXPORT
        @EXPORT_OK
        %colors
        $key_var
        %u2n
        %n2u
        $pua
        %PaperSizes
    );

    use Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(
        pdfkey
        float floats floats5 intg intgs
        mMin mMax
        HSVtoRGB RGBtoHSV HSLtoRGB RGBtoHSL RGBtoLUM
        namecolor namecolor_cmyk namecolor_lab optInvColor defineColor
        dofilter unfilter
        nameByUni uniByName initNameTable defineName
        page_size
        getPaperSizes
        str2dim
    );
    @EXPORT_OK = qw(
        pdfkey
        digest digestx digest16 digest32
        float floats floats5 intg intgs
        mMin mMax
        cRGB cRGB8 RGBasCMYK
        HSVtoRGB RGBtoHSV HSLtoRGB RGBtoHSL RGBtoLUM
        namecolor namecolor_cmyk namecolor_lab optInvColor defineColor
        dofilter unfilter
        nameByUni uniByName initNameTable defineName
        page_size  getPaperSizes
        str2dim
    );

=head1 NAME

PDF::Builder::Util - utility package for often-used methods across the package.

=cut

    %colors = PDF::Builder::Resource::Colors->get_colors();
    %PaperSizes = PDF::Builder::Resource::PaperSizes->get_paper_sizes();

    $key_var = 'CBA';

    $pua = 0xE000;

    %u2n = %{$PDF::Builder::Resource::Glyphs::u2n};
    %n2u = %{$PDF::Builder::Resource::Glyphs::n2u};
}

sub pdfkey {
    return $PDF::Builder::Util::key_var++;
}

sub digestx {
    my $len = shift;

    my $mask = $len - 1;
    my $ddata = join('', @_);
    my $mdkey = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789gT';
    my $xdata = '0' x $len;
    my $off = 0;
    foreach my $set (0 .. (length($ddata) << 1)) {
        $off += vec($ddata, $set, 4);
        $off += vec($xdata, ($set & $mask), 8);
        vec($xdata, ($set & ($mask << 1 | 1)), 4) = vec($mdkey, ($off & 0x7f), 4);
    }

    # foreach $set (0 .. $mask) {
    #     vec($xdata, $set, 8) = (vec($xdata, $set, 8) & 0x7f) | 0x40;
    # }

    # $off = 0;
    # foreach $set (0 .. $mask) {
    #     $off += vec($xdata, $set, 8);
    #     vec($xdata, $set, 8) = vec($mdkey, ($off & 0x3f), 8);
    # }

    return $xdata;
}

sub digest {
    return digestx(32, @_);
}

sub digest16 {
    return digestx(16, @_);
}

sub digest32 {
    return digestx(32, @_);
}

sub xlog10 {
    my $n = shift;

    if ($n) {
        return log(abs($n)) / log(10);
    } else { 
	    return 0;
    }
}

sub float {
    my $f = shift;
    my $mxd = shift() || 4;

    $f = 0 if abs($f) < 0.0000000000000001;
    my $ad = floor(xlog10($f) - $mxd);
    if      (abs($f - int($f)) < (10 ** (-$mxd))) {
        # just in case we have an integer
        return sprintf('%i', $f);
    } elsif ($ad > 0) {
        my $value = sprintf('%f', $f);
        # Remove trailing zeros
        $value =~ s/(\.\d*?)0+$/$1/;
        $value =~ s/\.$//;
        return $value;
    } else {
        my $value = sprintf('%.*f', abs($ad), $f);
        # Remove trailing zeros
        $value =~ s/(\.\d*?)0+$/$1/;
        $value =~ s/\.$//;
        return $value;
    }
}

sub floats { return map { float($_) } @_; }
sub floats5 { return map { float($_, 5) } @_; }

sub intg {
    my $f = shift;

    return sprintf('%i', $f);
}

sub intgs { return map { intg($_) } @_; }

sub mMin {
    my $n = HUGE_VAL();
    map { $n = ($n > $_) ? $_ : $n } @_;
    return $n;
}

sub mMax {
    my $n = -HUGE_VAL();
    map { $n = ($n < $_) ? $_ : $n } @_;
    return $n;
}

=head2 PREDEFINED COLORS

See the source of L<PDF::Builder::Resource::Colors> for a complete list.

B<Please Note:> This is an amalgamation of the X11, SGML and (X)HTML
specification sets.

There are many color model conversion and input conversion routines 
defined here.

=cut

sub cRGB {
    my @cmy = (map { 1 - $_ } @_);
    my $k = mMin(@cmy);
    return (map { $_ - $k } @cmy), $k;
}

sub cRGB8 {
    return cRGB(map { $_ / 255 } @_);
}

sub RGBtoLUM {
    my ($rr, $gg, $bb) = @_;
    return $rr * 0.299 + $gg * 0.587 + $bb * 0.114;
}

sub RGBasCMYK {
    my @rgb = @_;
    my @cmy = map { 1 - $_ } @rgb;
    my $k = mMin(@cmy) * 0.44;
    return (map { $_ - $k } @cmy), $k;
}

sub HSVtoRGB {
    my ($h,$s,$v) = @_;
    my ($rr,$gg,$bb, $i, $f, $p, $q, $t);

    if ($s == 0) {
        # achromatic (grey)
        return ($v,$v,$v);
    }

    $h %= 360;
    $h /= 60;       # sector 0 to 5
    $i = POSIX::floor($h);
    $f = $h - $i;   # factorial part of h
    $p = $v * (1 - $s);
    $q = $v * (1 - $s * $f);
    $t = $v * (1 - $s * ( 1 - $f ));

    if      ($i < 1) {
        $rr = $v;
        $gg = $t;
        $bb = $p;
    } elsif ($i < 2) {
        $rr = $q;
        $gg = $v;
        $bb = $p;
    } elsif ($i < 3) {
        $rr = $p;
        $gg = $v;
        $bb = $t;
    } elsif ($i < 4) {
        $rr = $p;
        $gg = $q;
        $bb = $v;
    } elsif ($i < 5) {
        $rr = $t;
        $gg = $p;
        $bb = $v;
    } else {
        $rr = $v;
        $gg = $p;
        $bb = $q;
    }

    return ($rr, $gg, $bb);
}

sub RGBquant {
    my ($q1, $q2, $h) = @_;
    while ($h < 0) {
	$h += 360;
    }
    $h %= 360;
    if      ($h < 60) {
        return $q1 + (($q2 - $q1) * $h / 60);
    } elsif ($h < 180) {
        return $q2;
    } elsif ($h < 240) {
        return $q1 + (($q2 - $q1) * (240 - $h) / 60);
    } else {
        return $q1;
    }
}

sub RGBtoHSV {
    my ($rr,$gg,$bb) = @_;

    my ($h,$s,$v, $min, $max, $delta);

    $min = mMin($rr, $gg, $bb);
    $max = mMax($rr, $gg, $bb);

    $v = $max;
    $delta = $max - $min;

    if ($delta > 0.000000001) {
        $s = $delta / $max;
    } else {
        $s = 0;
        $h = 0;
        return ($h,$s,$v);
    }

    if      ( $rr == $max ) {
        $h = ($gg - $bb) / $delta;
    } elsif ( $gg == $max ) {
        $h = 2 + ($bb - $rr) / $delta;
    } else {
        $h = 4 + ($rr - $gg) / $delta;
    }
    $h *= 60;
    if ($h < 0) {
	    $h += 360;
    }
    return ($h,$s,$v);
}

sub RGBtoHSL {
    my ($rr,$gg,$bb) = @_;

    my ($h,$s,$v, $l, $min, $max, $delta);

    $min = mMin($rr, $gg, $bb);
    $max = mMax($rr, $gg, $bb);
    ($h, $s, $v) = RGBtoHSV($rr, $gg, $bb);
    $l = ($max + $min) / 2.0;
    $delta = $max - $min;
    if ($delta < 0.00000000001) {
        return (0, 0, $l);
    } else {
        if ($l <= 0.5) {
            $s = $delta / ($max + $min);
        } else {
            $s = $delta / (2 - $max - $min);
        }
    }
    return ($h, $s, $l);
}

sub HSLtoRGB {
    my($h,$s,$l, $rr,$gg,$bb, $p1, $p2) = @_;

    if ($l <= 0.5) {
        $p2 = $l * (1 + $s);
    } else {
        $p2 = $l + $s - ($l * $s);
    }
    $p1 = 2 * $l - $p2;
    if ($s < 0.0000000000001) {
        $rr = $gg = $bb = $l;
    } else {
        $rr = RGBquant($p1, $p2, $h + 120);
        $gg = RGBquant($p1, $p2, $h);
        $bb = RGBquant($p1, $p2, $h - 120);
    }
    return ($rr,$gg,$bb);
}

sub optInvColor {
    my ($rr,$gg,$bb) = @_;

    my $ab = (0.2 * $rr) + (0.7 * $gg) + (0.1 * $bb);

    if ($ab > 0.45) {
        return(0,0,0);
    } else {
        return(1,1,1);
    }
}

sub defineColor {
    my ($name, $mx, $rr,$gg,$bb) = @_;
    $colors{$name} ||= [ map {$_ / $mx} ($rr,$gg,$bb) ];
    return $colors{$name};
}

# convert 3n (n=1..4) hex digits to RGB 0-1 values
# returns a triplet of values 0.0..1.0
sub rgbHexValues {
    my $name = lc(shift());  # # plus 3n hex digits
    # if <3 digits, pad with '0' (silent error)
    # if not 3n digits, ignore extras (silent error)
    # if >12 digits, ignore extras (silent error)
    my ($rr,$gg,$bb);
    while (length($name) < 4) { $name .= '0'; }
    if      (length($name) < 5) {  # zb. #fa4,          #cf0
        $rr = hex(substr($name, 1, 1)) / 0xf;
        $gg = hex(substr($name, 2, 1)) / 0xf;
        $bb = hex(substr($name, 3, 1)) / 0xf;
    } elsif (length($name) < 8) {  # zb. #ffaa44,       #ccff00
        $rr = hex(substr($name, 1, 2)) / 0xff;
        $gg = hex(substr($name, 3, 2)) / 0xff;
        $bb = hex(substr($name, 5, 2)) / 0xff;
    } elsif (length($name) < 11) { # zb. #fffaaa444,    #cccfff000
        $rr = hex(substr($name, 1, 3)) / 0xfff;
        $gg = hex(substr($name, 4, 3)) / 0xfff;
        $bb = hex(substr($name, 7, 3)) / 0xfff;
    } else {                      # zb. #ffffaaaa4444,  #ccccffff0000
        $rr = hex(substr($name, 1, 4)) / 0xffff;
        $gg = hex(substr($name, 5, 4)) / 0xffff;
        $bb = hex(substr($name, 9, 4)) / 0xffff;
    }

    return ($rr,$gg,$bb);
}

# convert 4n (n=1..4) hex digits to CMYK 0-1 values
# returns a quadruple of values 0.0..1.0
sub cmykHexValues {
    my $name = lc(shift());  # % plus 4n hex digits

    # if <4 digits, pad with '0' (silent error)
    # if not 4n digits, ignore extras (silent error)
    # if >16 digits, ignore extras (silent error)
    my ($c,$m,$y,$k);
    while (length($name) < 5) { $name .= '0'; }
    if      (length($name) < 6) {  # zb. %cmyk
        $c = hex(substr($name, 1, 1)) / 0xf;
        $m = hex(substr($name, 2, 1)) / 0xf;
        $y = hex(substr($name, 3, 1)) / 0xf;
        $k = hex(substr($name, 4, 1)) / 0xf;
    } elsif (length($name) < 10) { # zb. %ccmmyykk
        $c = hex(substr($name, 1, 2)) / 0xff;
        $m = hex(substr($name, 3, 2)) / 0xff;
        $y = hex(substr($name, 5, 2)) / 0xff;
        $k = hex(substr($name, 7, 2)) / 0xff;
    } elsif (length($name) < 14) { # zb. %cccmmmyyykkk
        $c = hex(substr($name, 1, 3)) / 0xfff;
        $m = hex(substr($name, 4, 3)) / 0xfff;
        $y = hex(substr($name, 7, 3)) / 0xfff;
        $k = hex(substr($name, 10, 3)) /0xfff;
    } else {                       # zb. %ccccmmmmyyyykkkk
        $c = hex(substr($name, 1, 4)) / 0xffff;
        $m = hex(substr($name, 5, 4)) / 0xffff;
        $y = hex(substr($name, 9, 4)) / 0xffff;
        $k = hex(substr($name, 13, 4)) / 0xffff;
    }

    return ($c,$m,$y,$k);
}

# convert 3n (n=1..4) hex digits to HSV 0-360, 0-1 values
# returns a triplet of values 0.0..360.0, 2x0.0..1.0
sub hsvHexValues {
    my $name = lc(shift());  # ! plus 3n hex digits

    # if <3 digits, pad with '0' (silent error)
    # if not 3n digits, ignore extras (silent error)
    # if >12 digits, ignore extras (silent error)
    my ($h,$s,$v);
    while (length($name) < 4) { $name .= '0'; }
    if      (length($name) < 5) {
        $h = 360 * hex(substr($name, 1, 1)) / 0x10;
        $s =       hex(substr($name, 2, 1)) / 0xf;
        $v =       hex(substr($name, 3, 1)) / 0xf;
    } elsif (length($name) < 8) {
        $h = 360 * hex(substr($name, 1, 2)) / 0x100;
        $s =       hex(substr($name, 3, 2)) / 0xff;
        $v =       hex(substr($name, 5, 2)) / 0xff;
    } elsif (length($name) < 11) {
        $h = 360 * hex(substr($name, 1, 3)) / 0x1000;
        $s =       hex(substr($name, 4, 3)) / 0xfff;
        $v =       hex(substr($name, 7, 3)) / 0xfff;
    } else {
        $h = 360 * hex(substr($name, 1, 4)) / 0x10000;
        $s =       hex(substr($name, 5, 4)) / 0xffff;
        $v =       hex(substr($name, 9, 4)) / 0xffff;
    }

    return ($h,$s,$v);
}

# convert 3n (n=1..4) hex digits to LAB 0-100, -100-100 values
# returns a triplet of values 0.0..100.0, 2x-100.0..100.0
sub labHexValues {
    my $name = lc(shift());  # & plus 3n hex digits

    # if <3 digits, pad with '0' (silent error)
    # if not 3n digits, ignore extras (silent error)
    # if >12 digits, ignore extras (silent error)
    my ($ll,$aa,$bb);
    while (length($name) < 4) { $name .= '0'; }
    if      (length($name) < 5) {
        $ll =  100*hex(substr($name, 1, 1)) / 0xf;
        $aa = (200*hex(substr($name, 2, 1)) / 0xf) - 100;
        $bb = (200*hex(substr($name, 3, 1)) / 0xf) - 100;
    } elsif (length($name) < 8) {
        $ll =  100*hex(substr($name, 1, 2)) / 0xff;
        $aa = (200*hex(substr($name, 3, 2)) / 0xff) - 100;
        $bb = (200*hex(substr($name, 5, 2)) / 0xff) - 100;
    } elsif (length($name) < 11) {
        $ll =  100*hex(substr($name, 1, 3)) / 0xfff;
        $aa = (200*hex(substr($name, 4, 3)) / 0xfff) - 100;
        $bb = (200*hex(substr($name, 7, 3)) / 0xfff) - 100;
    } else {
        $ll =  100*hex(substr($name, 1, 4)) / 0xffff;
        $aa = (200*hex(substr($name, 5, 4)) / 0xffff) - 100;
        $bb = (200*hex(substr($name, 9, 4)) / 0xffff) - 100;
    }

    return ($ll,$aa,$bb);
}

sub namecolor {
    my $name = shift;

    unless (ref $name) {
        $name = lc($name);
        $name =~ s/[^\#!%\&\$a-z0-9]//g;
    }

    if      ($name =~ /^[a-z]/) { # name spec.
        return namecolor($colors{$name});
    } elsif ($name =~ /^#/) {     # rgb spec.
        return floats5(rgbHexValues($name));
    } elsif ($name =~ /^%/) {     # cmyk spec.
        return floats5(cmykHexValues($name));
    } elsif ($name =~ /^!/) {     # hsv spec.
        return floats5(HSVtoRGB(hsvHexValues($name)));
    } elsif ($name =~ /^&/) {     # hsl spec.
        return floats5(HSLtoRGB(hsvHexValues($name)));
    } else {                      # or it is a ref ?
        return floats5(@{$name || [0.5,0.5,0.5]});
    }
}

sub namecolor_cmyk {
    my $name = shift;
    
    unless (ref($name)) {
        $name = lc($name);
        $name =~ s/[^\#!%\&\$a-z0-9]//g;
    }

    if      ($name =~ /^[a-z]/) { # name spec.
        return namecolor_cmyk($colors{$name});
    } elsif ($name =~ /^#/) {     # rgb spec.
        return floats5(RGBasCMYK(rgbHexValues($name)));
    } elsif ($name =~ /^%/) {     # cmyk spec.
        return floats5(cmykHexValues($name));
    } elsif ($name =~ /^!/) {     # hsv spec.
        return floats5(RGBasCMYK(HSVtoRGB(hsvHexValues($name))));
    } elsif ($name =~ /^&/) {     # hsl spec.
        return floats5(RGBasCMYK(HSLtoRGB(hsvHexValues($name))));
    } else {                      # or it is a ref ?
        return floats5(RGBasCMYK(@{$name || [0.5,0.5,0.5]}));
    }
}

# note that an angle of 360 degrees is treated as 0 radians by deg2rad.
sub namecolor_lab {
    my $name = shift;

    unless (ref($name)) {
        $name = lc($name);
        $name  =~ s/[^\#!%\&\$a-z0-9]//g;
    }

    if      ($name =~ /^[a-z]/) { # name spec.
        return namecolor_lab($colors{$name});
    } elsif ($name =~ /^\$/) {    # lab spec.
        return floats5(labHexValues($name));
    } elsif ($name =~ /^#/) {     # rgb spec.
        my ($h,$s,$v) = RGBtoHSV(rgbHexValues($name));
        my $aa = cos(deg2rad($h)) * $s * 100;
        my $bb = sin(deg2rad($h)) * $s * 100;
        my $ll = 100 * $v;
        return floats5($ll,$aa,$bb);
    } elsif ($name =~ /^!/) {     # hsv spec.
        # fake conversion
        my ($h,$s,$v) = hsvHexValues($name);
        my $aa = cos(deg2rad($h)) * $s * 100;
        my $bb = sin(deg2rad($h)) * $s * 100;
        my $ll = 100 * $v;
        return floats5($ll,$aa,$bb);
    } elsif ($name =~ /^&/) {     # hsl spec.
        my ($h,$s,$v) = hsvHexValues($name);
        my $aa = cos(deg2rad($h)) * $s * 100;
        my $bb = sin(deg2rad($h)) * $s * 100;
        ($h,$s,$v) = RGBtoHSV(HSLtoRGB($h,$s,$v));
        my $ll = 100 * $v;
        return floats5($ll,$aa,$bb);
    } else {                      # or it is a ref ?
        my ($h,$s,$v) = RGBtoHSV(@{$name || [0.5,0.5,0.5]});
        my $aa = cos(deg2rad($h)) * $s * 100;
        my $bb = sin(deg2rad($h)) * $s * 100;
        my $ll = 100 * $v;
        return floats5($ll,$aa,$bb);
    }
}

=head2 STREAM FILTERS

There are a number of functions here to handle stream filtering.

=cut

sub unfilter {
    my ($filter, $stream) = @_;

    if (defined $filter) {
        # we need to fix filter because it MAY be
        # an array BUT IT COULD BE only a name
        if (ref($filter) !~ /Array$/) {
            $filter = PDFArray($filter);
        }
        my @filts;
        my ($hasflate) = -1;
        my ($temp, $i, $temp1);

        @filts = map { ("PDF::Builder::Basic::PDF::Filter::" . $_->val())->new() } $filter->elements();

        foreach my $f (@filts) {
            $stream = $f->infilt($stream, 1);
        }
    }

    return $stream;
}

sub dofilter {
    my ($filter, $stream) = @_;

    if (defined $filter) {
        # we need to fix filter because it MAY be
        # an array BUT IT COULD BE only a name
        if (ref($filter) !~ /Array$/) {
            $filter = PDFArray($filter);
        }
        my @filts;
        my $hasflate = -1;
        my ($temp, $i, $temp1);

        @filts = map { ("PDF::Builder::Basic::PDF::Filter::" . $_->val())->new() } $filter->elements();

        foreach my $f (@filts) {
            $stream = $f->outfilt($stream, 1);
        }
    }

    return $stream;
}

=head2 PREDEFINED GLYPH-NAMES

See the file C<uniglyph.txt> for a complete list.

B<Please Note:> You may notice that apart from the 'AGL/WGL4', names
from the XML, (X)HTML and SGML specification sets have been included
to enable interoperability towards PDF.

There are a number of functions here to handle various
aspects of glyph identification.

=cut

sub nameByUni {
    my $e = shift;

    return $u2n{$e} || sprintf('uni%04X', $e);
}

sub uniByName {
    my $e = shift;
    if ($e =~ /^uni([0-9A-F]{4})$/) {
        return hex($1);
    }
    return $n2u{$e} || undef;
}

sub initNameTable {
    %u2n = %{$PDF::Builder::Resource::Glyphs::u2n};
    %n2u = %{$PDF::Builder::Resource::Glyphs::n2u};
    $pua = 0xE000;
    return;
}

sub defineName {
    my $name = shift;

    return $n2u{$name} if defined $n2u{$name};

    $pua++ while defined $u2n{$pua};

    $u2n{$pua} = $name;
    $n2u{$name} = $pua;

    return $pua;
}

=head2 PREDEFINED PAPER SIZES

Dimensions are in points.

=head3 paper_size

    @box_corners = paper_size($x1,$y1, $x2,$y2);

=over

Returns an array ($x1,$y1, $x2,$y2) (full bounding box).

=back

    @box_corners = paper_size($x1,$y1);

=over

Returns an array (0,0, $x1,$y1) (half bounding box).

=back

    @box_corners = paper_size($media_name);

=over

Returns an array (0,0, paper_width,paper_height) for the named media.

=back

    @box_corners = paper_size($x1);

=over

Returns an array (0,0, $x1,$x1) (single quadratic).

Otherwise, array (0,0, 612,792) (US Letter dimensions) is returned.

=back

=cut

sub page_size {
    my ($x1,$y1, $x2,$y2) = @_;

    if      (defined $x2) {
        # full bbox
        return ($x1,$y1, $x2,$y2);
    } elsif (defined $y1) {
        # half bbox
        return (0,0, $x1,$y1);
    } elsif (defined $PaperSizes{lc $x1}) {
        # textual spec.
        return (0,0, @{$PaperSizes{lc $x1}});
    } elsif ($x1 =~ /^[\d\.]+$/) {
        # single quadratic
        return(0,0, $x1,$x1);
    } else {
        # PDF default (US letter)
        return (0,0, 612,792);
    }
}

=head3 getPaperSizes

    %sizes = getPaperSizes();

=over

Returns a hash containing the available paper size aliases as keys and
their dimensions as a two-element array reference.

See the source of L<PDF::Builder::Resource::PaperSizes> for the complete list.

=back

=cut

sub getPaperSizes {
    my %sizes = ();
    foreach my $type (keys %PaperSizes) {
        $sizes{$type} = [@{$PaperSizes{$type}}];
    }
    return %sizes;
}

=head2 STRING TO DIMENSION

Convert a string "number [unit]" to the value in desired units. Units are
case-insensitive (the input is first folded to lower case).

Supported units: mm, cm, in (inch), pt (Big point, 72/inch), ppt (printer's
point, 72.27/inch), pc (pica, 6/inch), dd (Didot point, 67.5532/inch), and
cc (Ciceros, 5.62943/inch). More can be added easily. 
Invalid units are a fatal error.

=head3 str2dim

    $value = str2dim($string, $type, $default_units);

=over

C<$string> contains a number and optionally, a unit. Space(s) between the number
and the unit are optional. E.g., '200', '35.2 mm', and '1.5in' are all allowable
input strings.

C<$type> is for validation of the input $string's numeric value. The first 
character is B<i> for an I<integer> is required (no decimal point), or B<f> for
other (floating point) numbers. Next is an optional B<c> to indicate that an
out-of-range input value is to be silently I<clamped> to be within the given 
range (the default is to raise a fatal error). Finally, an optional I<range>
expression: {lower limit,upper limit}. The limits are either numbers or B<*> (to
indicate +/- infinity (no limit) on that end of the range). B<{> is B<[> to say 
that the lower limit is I<included> in the range, while B<(> says that the 
lower limit is I<excluded> from the range. Likewise, B<}> is B<]> for 
I<included> upper limit, and B<)> for I<excluded>. The limits (and silent 
clamping, or fatal error if the input is out of range) are against the input 
value, before conversion to the output units.

Example types:

=over

=item C<'f(*,*)'>  no limits (the default) -- all values OK

=item C<'i(0,*)'>  integer greater than 0

=item C<'fc[-3.2,7.86]'>  a number between -3.2 and 7.86, with value clamped to 
be within that range (including the endpoints)

=back

C<$default_units> is a required string, giving the units that the input is
converted to. For example, if the default units are 'pt', and the input string
'2 in', the output value would be '144'. If the input string has no explicit 
units, it is assumed to be in the default units (no conversion is done).

=back

=cut

# convert string to numeric, converting units to default unit
# recognized units are mm, cm, in, pt, ppt (printer's point, 72.27/inch), pc
# allow space between number and unit
# TBD for floats being clamped and limit is not-inclusive, what value to clamp?
#        currently limit +/- 1.0
# if string is empty or all blank, return 0
sub str2dim {
	my ($string, $type, $defUnit) = @_;

	my ($defUnitIdx, $value, $unit, $unitIdx);
	# unit names, divisor to get inches
	# ppt = printer's (old) points, dd = didot ppoints, cc = ciceros
	my @units   = ( 'mm',  'cm',  'in',  'pt',  'ppt', 'pc', 
			'dd',	      'cc' );
	my @convert = ( 25.4,  2.54,  1,     72,    72.27, 6, 
			67.5532,      5.62943 );

	# validate default unit
	$defUnit = lc($defUnit);
	for ($defUnitIdx = 0; $defUnitIdx < @units; $defUnitIdx++) {
		if ($units[$defUnitIdx] eq $defUnit) { last; }
	}
	# fell through? invalid default unit
	if ($defUnitIdx >= @units) {
		die "Error: Unknown default dimensional unit '$defUnit'\n";
	}

	$string =~ s/\s//g;  # remove all whitespace
	if ($string eq '') { return 0; }

	if      ($string =~ m/^([.0-9-]+)$/i) { 
		$value = $1; 
		$unit  = ''; 
	} elsif ($string =~ m/^([.0-9-]+)(.*)$/i) { 
		$value = $1; 
		$unit  = lc($2); 
	} else {
		die "Error: Unable to decipher dimensional string '$string'\n";
	}
	# is unit good? leaves unitIdx as index into arrays
	if ($unit ne '') {
		for ($unitIdx = 0; $unitIdx < @units; $unitIdx++) {
			if ($units[$unitIdx] eq $unit) { last; }
		}
		# fell through? invalid unit
		if ($unitIdx >= @units) {
			die "Error: Unknown dimensional unit '$unit' in '$string'\n";
		}
	} # else is bare number

	# validate number. if type = i (int), only integer permitted
	# if type = f (float), any valid float OK (no E notation)
	# in either case, must not be negative
	# note: no range checking (might be overflow)
	if ($value =~ m/^-/) { die "Error: Dimensional value '$value $unit' cannot be negative\n"; }

	$type = lc($type);
	$type =~ s/\s//g;
	if ($type =~ m/^[fi]/) {
		# OK type
	} else {
		die "Error: Invalid type for dimension. Must be 'f' or 'i'\n";
	}
	if      ($type =~ m/^i/) {
		if (!($value =~ m/^\d+$/)) {
			die "Error: $value is not a valid integer\n";
		}
	} else {  # presumably f (float)
		if (!($value =~ m/^\.\d+$/ ||
		      $value =~ m/^\d+\.\d+$/ ||
		      $value =~ m/^\d+\.?$/)) {
			die "Error: $value is not a valid float\n";
		}
	}

	# $value is a legit number, $unit is OK unit. convert if unit different
	# from default unit
	if ($unit eq '' || $unit eq $defUnit) {
		# assume bare number is default unit
	} else {
		# convert to inches, and back to defUnit
		$value /= $convert[$unitIdx];
		$value *= $convert[$defUnitIdx];
	}

	# range check and optionally clamp: look at remainder of type
	$type = substr($type, 1);
	if ($type ne '') {
		# format is optional c (for clamp)
		#           [ or ( for lower value is included or excluded from range
		#           lower value or * (- infinity)
		#           comma ,
		#           upper value or * (+ infinity)
		#           ] or ) for upper value is included or excluded from range
		my $clamp = 0;  # default to False (error if out of range)
		if ($type =~ m/^c/) {
			$clamp = 1;
			$type = substr($type, 1); # MUST be at least 5 more char
		}
		
		# get lower and upper bounds
		my $lbInf = 1;  # * for value T
		my $ubInf = 1;  # * for value T
		my ($lb,$ub);   # non-* values
		my $lbInc = 0;  # [ include T, ( include F
		my $ubInc = 0;  # ] include T, ) include F
		if ($type =~ m/^([\[\(])([^,]+),([^\]\)]+)([\]\)])$/) {
			$lbInc = ($1 eq '[');
			$lbInf = ($2 eq '*');
			$ubInf = ($3 eq '*');
			$ubInc = ($4 eq ']');
                        if (!$lbInf) { 
				$lb = $2;
				# must be numeric. don't care int/float
				if ($lb =~ m/^-?\.\d+$/ ||
				    $lb =~ m/^-?\d+\.\d+/ ||
				    $lb =~ m/^-?\d+\.?$/ ) {
					# is numeric
					if ($lbInc && $value < $lb) {
					       if ($clamp) { $value = $lb; }
					       else { die "Error: Value $value is smaller than the limit $lb\n"; }
					}
					if (!$lbInc && $value <= $lb) {
					       if ($clamp) { $value = $lb+1; }
					       else { die "Error: Value $value is smaller or equal to the limit $lb\n"; }
					}
				} else {
					die "Error: Range lower bound '$lb' not * or number\n";
				}
			} # if lb is -inf, don't care what value is
                        if (!$ubInf) { 
				$ub = $3;
				# must be numeric. don't care int/float
				if ($ub =~ m/^-?\.\d+$/ ||
				    $ub =~ m/^-?\d+\.\d+/ ||
				    $ub =~ m/^-?\d+\.?$/ ) {
					# is numeric
					if ($ubInc && $value > $ub) {
					       if ($clamp) { $value = $ub; }
					       else { die "Error: Value $value is larger than the limit $ub\n"; }
					}
					if (!$ubInc && $value >= $ub) {
					       if ($clamp) { $value = $ub-1; }
					       else { die "Error: Value $value is larger or equal to the limit $ub\n"; }
					}
				} else {
					die "Error: Range upper bound '$ub' not * or number\n";
				}
			} # if ub is +inf, don't care what value is

		} else {
			die "Error: Invalid range specification '$type'\n";
		}
	}
	
	return $value;
} # end of str2dim()

1;

__END__
