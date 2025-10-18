#!/usr/bin/perl
use strict;
use warnings;

use lib qw(../../lib);

{
    my $code = '012345678905';
    use SVG::Barcode::UPCA;

    my $obj = SVG::Barcode::UPCA->new;

    my $svg_black = $obj->plot($code);

    $obj->foreground('red');
    $obj->textsize(0);
    $obj->lineheight(20);

    my $svg_red = $obj->plot($code);

    open(my $fh_black, '>', "${code}_black_text.svg") or die "Cannot open ${code}_black_text.svg: $!";
    print $fh_black $svg_black;
    close($fh_black) or warn "Cannot close ${code}_black_text.svg: $!";

    open(my $fh_red, '>', "${code}_red_notext.svg") or die "Cannot open ${code}_red_notext.svg: $!";
    print $fh_red $svg_red;
    close($fh_red) or warn "Cannot close ${code}_red_notext.svg: $!";
}

{
    my $code = '1234567890128';
    use SVG::Barcode::EAN13;

    my $obj = SVG::Barcode::EAN13->new;

    my $svg_black = $obj->plot($code);

    $obj->foreground('red');
    $obj->textsize(0);
    $obj->lineheight(20);

    my $svg_red = $obj->plot($code);

    open(my $fh_black, '>', "${code}_black_text.svg") or die "Cannot open ${code}_black_text.svg: $!";
    print $fh_black $svg_black;
    close($fh_black) or warn "Cannot close ${code}_black_text.svg: $!";

    open(my $fh_red, '>', "${code}_red_notext.svg") or die "Cannot open ${code}_red_notext.svg: $!";
    print $fh_red $svg_red;
    close($fh_red) or warn "Cannot close ${code}_red_notext.svg: $!";
}

{
    my $code = '01234565';
    use SVG::Barcode::UPCE;

    my $obj = SVG::Barcode::UPCE->new;

    my $svg_black = $obj->plot($code);

    $obj->foreground('red');
    $obj->textsize(0);
    $obj->lineheight(20);

    my $svg_red = $obj->plot($code);

    open(my $fh_black, '>', "${code}_black_text.svg") or die "Cannot open ${code}_black_text.svg: $!";
    print $fh_black $svg_black;
    close($fh_black) or warn "Cannot close ${code}_black_text.svg: $!";

    open(my $fh_red, '>', "${code}_red_notext.svg") or die "Cannot open ${code}_red_notext.svg: $!";
    print $fh_red $svg_red;
    close($fh_red) or warn "Cannot close ${code}_red_notext.svg: $!";
}

{
    my $code = '12345670';
    use SVG::Barcode::EAN8;

    my $obj = SVG::Barcode::EAN8->new;

    my $svg_black = $obj->plot($code);

    $obj->foreground('red');
    $obj->textsize(0);
    $obj->lineheight(20);

    my $svg_red = $obj->plot($code);

    open(my $fh_black, '>', "${code}_black_text.svg") or die "Cannot open ${code}_black_text.svg: $!";
    print $fh_black $svg_black;
    close($fh_black) or warn "Cannot close ${code}_black_text.svg: $!";

    open(my $fh_red, '>', "${code}_red_notext.svg") or die "Cannot open ${code}_red_notext.svg: $!";
    print $fh_red $svg_red;
    close($fh_red) or warn "Cannot close ${code}_red_notext.svg: $!";
}
