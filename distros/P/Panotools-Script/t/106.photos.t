#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Photos;
ok (1);

my $photos = new Panotools::Photos ('t/data/cemetery/dscn4905.jpg', 't/data/cemetery/dscn4906.jpg');
ok (scalar ($photos->Paths) == 2);

$photos->Paths ('t/data/cemetery/dscn4907.jpg', 't/data/cemetery/dscn4908.jpg', 't/data/cemetery/dscn4909.jpg');
ok (scalar ($photos->Paths) == 5);

ok ($photos->Stub eq 't/data/cemetery/dscn4905-dscn4909');

ok ($photos->Bracketed == 0);

ok ($photos->FOV == 54.4);
ok ($photos->FOV (0) == 54.4);
ok ($photos->FOV (-1) == 54.4);

ok (scalar $photos->SplitInterval (10) == 3);
ok (scalar $photos->SplitInterval (15) == 2);
ok (scalar $photos->SplitInterval (20) == 2);
ok (scalar $photos->SplitInterval (25) == 2);
ok (scalar $photos->SplitInterval (30) == 1);

# this one deosn't have any EXIF info
$photos = new Panotools::Photos ('t/data/equirectangular/equirectangular.jpg');
ok (defined $photos->FOV == 0);

ok (scalar $photos->SplitInterval (15) == 1);

$photos = new Panotools::Photos;

$photos->[0] = {path => 'IMG_0001.JPG', exif => {ExposureTime => '1/2'}};
$photos->[1] = {path => 'IMG_0002.JPG', exif => {ExposureTime => '1/4'}};
$photos->[2] = {path => 'IMG_0003.JPG', exif => {ExposureTime => '2'}};
$photos->[3] = {path => 'IMG_0004.JPG', exif => {ExposureTime => '1/2'}};
$photos->[4] = {path => 'IMG_0005.JPG', exif => {ExposureTime => '1/4'}};
$photos->[5] = {path => 'IMG_0006.JPG', exif => {ExposureTime => '2'}};
$photos->[6] = {path => 'IMG_0007.JPG', exif => {ExposureTime => '1/2'}};
$photos->[7] = {path => 'IMG_0008.JPG', exif => {ExposureTime => '1/4'}};
$photos->[8] = {path => 'IMG_0009.JPG', exif => {ExposureTime => '2'}};

my $speeds = $photos->Speeds;
is ((join ':', @{$speeds}), '2:1/2:1/4');
ok ($photos->Bracketed == 1);
ok ($photos->Layered == 0);

# http://www.cpantesters.org/cpan/report/6a000430-b5c0-11df-af27-ffdf23310e15
is (Panotools::Photos::_normalise ('2'), 2, '_normalise');
is (Panotools::Photos::_normalise ('1/2'), 0.5, '_normalise');
is (Panotools::Photos::_normalise ('1/4'), 0.25, '_normalise');

# sequences have to be in strict order
$photos->[6] = {path => 'IMG_0007.JPG', exif => {ExposureTime => '1/4'}};
$photos->[7] = {path => 'IMG_0008.JPG', exif => {ExposureTime => '1/2'}};

is ((join ':', @{$photos->Speeds}), '2:1/2:1/4');
ok ($photos->Bracketed == 0);
ok ($photos->Layered == 1);
ok ($photos->Layered (8) == 1);
ok ($photos->Layered (9) == 0);

$photos->[6] = {path => 'IMG_0007.JPG', exif => {ExposureTime => '1/2'}};
$photos->[7] = {path => 'IMG_0008.JPG', exif => {ExposureTime => '1/4'}};
ok ($photos->Bracketed == 1);

# sequences have to have equal numbers of each exposure time
delete $photos->[8];
ok ($photos->Bracketed == 0);
ok ($photos->Layered == 1);
is ((join ':', @{$photos->Speeds}), '2:1/2:1/4');

is ((join ':', $photos->AverageRGB), '1:1:1');

$photos->[0]->{exif}->{RedBalance} = 2;
$photos->[1]->{exif}->{RedBalance} = 4;
is ((join ':', $photos->AverageRGB), '1:1:1');
$photos->[0]->{exif}->{GreenBalance} = 2;
$photos->[1]->{exif}->{GreenBalance} = 2;
$photos->[0]->{exif}->{BlueBalance} = 2;
$photos->[1]->{exif}->{BlueBalance} = 2;

is ((join ':', $photos->AverageRGB), '3:2:2');
