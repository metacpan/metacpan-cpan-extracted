package TeX::XDV::Print;
use strict;
use warnings;
use TeX::XDV::Parse ':constants';

@TeX::XDV::Print::ISA = qw/TeX::DVI::Print/;

sub dir {
    my ($self, $ord, $dir) = @_;
    my $d = $dir == 1 ? 'horizontal' : $dir == 0 ? 'vertical' : 'unknown';
    print "Dir\t$ord, $d\n";
}

sub native_font_def {
    # k : font id
    # ps: point size  /* skip point size */ (from dvi.c)
    #   : flags
    #   : ps name len
    #   : family name len
    #   : style name len
    # n : font_name
    #   : fam_name
    #   : sty_name
    #   : rgba_color
    #   : nvars
    #   : variations * nvars (not used?)
    #   : extend
    #   : slant
    #   : embolden
    my ($self,$ord,$k,$ps,$fl,$plen,$flen,$slen,$font,$fam,$sty,@more) = @_;

    my $dir   = $fl & XDV_FLAG_VERTICAL ? 1            : 0;
    my $color = $fl & XDV_FLAG_COLORED  ? shift(@more) : 0xffffffff;

    my ($nvars, @vars) = (0);
    if ($fl & XDV_FLAG_VARIATIONS) {
        $nvars = shift @more;
        push( @vars, shift( @more ) ) for 1 .. 2*$nvars;
    }

    my $extend = $fl & XDV_FLAG_EXTEND   ? shift(@more) : 0x00010000;
    my $slant  = $fl & XDV_FLAG_SLANT    ? shift(@more) : 0;
    my $bold   = $fl & XDV_FLAG_EMBOLDEN ? shift(@more) : 0;

    local $" = ',';  # for @vars
    print "NatFont\t$ord, ...\n";
    print "    font id.................: $k\n";
    print "    point size..............: $ps\n";
    print "    flags...................: $fl\n";
    print "    postscript name length..: $plen\n";
    print "    family name length......: $flen\n";
    print "    style name length.......: $slen\n";
    print "    font name...............: $font\n";
    print "    family name.............: $fam\n";
    print "    style name..............: $sty\n";
    print "    rgba color..............: $color\n";
    print "    number variations.......: $nvars\n";
    print "    variations..............: @vars\n";
    print "    extend..................: $extend\n";
    print "    slant...................: $slant\n";
    print "    embolden................: $bold\n";
}

sub glyph_string {
    my ($self, $ord, $width, $len, @more) = @_;
    my @x_locs = @more[0 .. $len-1];
    my @glyphs = @more[$len .. 2*$len-1];
    local $" = ',';
    print "GlyphSt\t$ord, ...\n";
    print "    width...................: $width\n";
    print "    length..................: $len\n";
    print "    x_locs..................: @x_locs\n";
    print "    glyphs..................: @glyphs\n";
}

sub glyph_array {
    my ($self, $ord, $width, $len, @more) = @_;
    my @x_locs = @more[ map { 2*$_ } 1 .. $len-1 ];
    my @y_locs = @more[ map { 2*$_+1 } 1 .. $len-1 ];
    my @glyphs = @more[ 2*$len+2 .. 3*$len-1 ];
    local $" = ',';
    print "GlyphAr\t$ord, ...\n";
    print "    width...................: $width\n";
    print "    length..................: $len\n";
    print "    x_locs..................: @x_locs\n";
    print "    y_locs..................: @y_locs\n";
    print "    glyphs..................: @glyphs\n";
}

sub pic_file {
    my ($self, $ord, $t, $a, $b, $c, $d, $e, $f, $pg, $l, $p ) = @_;
    print "PicFile\t$ord, ...\n";
    print "    box type................: $t\n";
    print "    a.......................: $a\n";
    print "    b.......................: $b\n";
    print "    c.......................: $c\n";
    print "    d.......................: $d\n";
    print "    e.......................: $e\n";
    print "    f.......................: $f\n";
    print "    page number.............: $pg\n";
    print "    path length.............: $l\n";
    print "    path....................: $p\n";
}

1;

