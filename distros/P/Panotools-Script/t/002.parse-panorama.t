#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use_ok ('Panotools::Script::Line::Panorama');

my $panorama = new Panotools::Script::Line::Panorama;

is ($panorama->{w}, '1000', 'width defaults to 1000 pixels');
is ($panorama->{h}, '500', 'height defaults to 500 pixels');
is ($panorama->{f}, '2', 'projection defaults to equirectangular');
ok ($panorama->{v} == '360.0', 'fov defaults to 360.0 degrees');
is ($panorama->{n}, '"JPEG q100"', 'filetype defaults to JPEG');

$panorama->{v} = '180.0';
is ($panorama->{v}, '180.0', 'fov is set to 180.0');

$panorama->{f} = '0';
is ($panorama->{f}, '0', 'projection is set to rectilinear');

$panorama->Parse ("p w3000 h1500 f1 v360.0 b1 u20 nJPEG a\"some test junk\" t\"some other test junk\"\n\n");

# bdku
is ($panorama->{f}, '1', 'projection is set to cylindrical');
is ($panorama->{n}, 'JPEG', 'filetype is set to JPEG');

$panorama->{f} = '2';
$panorama->{n} = '"TIFF_m c:LZW"';

like ($panorama->Assemble, '/ n"TIFF_m c:LZW"/', 'multi TIFF written as n"TIFF_m c:LZW"');
like ($panorama->Assemble, '/ f2/', 'projection equirectangular written as f2');
like ($panorama->Assemble, '/ b1/', 'brightness correction written as b1');
like ($panorama->Assemble, '/ u20/', '20 pixel feather  written as u20');
unlike ($panorama->Assemble, '/test junk/', 'invalid entries removed');

ok ($panorama->Report);
