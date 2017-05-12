#!/usr/bin/perl

use strict;

use SWF::Builder;
use Getopt::Long;
use Pod::Usage;
#use Encode;

my $fp = $ENV{SYSTEMROOT}.'/fonts/';  # for Windows.

my ($mes, $font, $size, $color, $back, $framesize, $filename, $help)
 = ('SWF::Builder', 'ariali.ttf', 20, 'ffffff', '000000', '234x60', 'flowmes.swf', 0);

GetOptions('font=s' => \$font, 'size=i' => \$size, 'color=s' => \$color, 'back=s' => \$back, 'framesize=s' => \$framesize, 'file=s', \$filename, 'help', \$help);


pod2usage(-verbose=>2) if $help;
pod2usage(1) unless @ARGV;

my @framesize = map {$_-1} split /[x,]/, $framesize;
my $mes = shift;
#$mes = Encode::decode('ShiftJIS', $mes);

my $y = ($framesize[1] - $size)>>1;

$font = $fp.$font unless -e $font;

my $m = SWF::Builder->new(FrameRate => 60, FrameSize => [0,0,@framesize], BackgroundColor => $back);

my $font = $m->new_font($font);
my $text = $m->new_static_text
    ->font($font)
    ->size($size)
    ->color($color)
    ->text($mes);
    ;

my @tbox = $text->get_bbox;
$tbox[2]+=10;
my $maskbox = $m->new_shape
    ->linestyle('none')
    ->fillstyle('ffffff')
    ->box(@tbox);
my $maskbox2 = $m->new_shape
    ->linestyle('none')
    ->fillstyle('ffffff')
    ->box(0,0,@framesize);
my $maskbox3 = $m->new_shape
    ->linestyle('none')
    ->fillstyle('ffffff')
    ->box(0,0,11,$framesize[1]);

my $mi = $maskbox->place_as_mask;
my $mi2 = $maskbox2->place_as_mask;
my $mi3 = $maskbox3->place_as_mask;

my $ti = $text->place(clip_with=>$mi);
$ti->moveto(10,$y);

my $ti2 = $text->place(clip_with=>$mi2);
$ti2->scale(500,1)->moveto(10,$y);

my $ti3 = $text->place(clip_with=>$mi3);
$ti3->scale(3,1)->moveto(10,$y);

for (0..$tbox[2]) {
    $mi->moveto(10-$tbox[2]+$_,$y);
    $mi3->moveto(10+$_,0);
    $ti3->moveto(10-2*($_+1),$y);
    $mi2->moveto(10+11+$_,0);
    $ti2->moveto(10+11-499*($_+5),$y);
}

$m->save($filename);

__END__

=head1 NAME

flowmes.plx - Creates flow-in-message movie.

=head1 SYNOPSIS

flowmes.plx [options] message

  Options and defaults
    --font=aliali.ttf    Set font.
    --size=20            Set letter size.
    --color=ffffff       Set letter color.
    --back=000000        Set background color.
    --framesize=234x60   Set frame size. Width x height.
    --file=flowmes.swf   Set output file name.
    --help               Show help.

=head1 DESCRIPTION

This is a sample program of SWF::Builder. It creates a flow-in-message(?) movie.

=head1 TODO

Does anyone know what this effect is called?

=head1 COPYRIGHT

Copyright 2003 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
