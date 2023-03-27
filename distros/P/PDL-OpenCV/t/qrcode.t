use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::IO::Pic;
use PDL::OpenCV;
use PDL::OpenCV::Objdetect;
use PDL::OpenCV::Imgcodecs;
#use PDL::OpenCV::Highgui;

my $qrd = PDL::OpenCV::QRCodeDetector->new;
isa_ok $qrd, 'PDL::OpenCV::QRCodeDetector';
my $vfile = 't/qrcode.png';
my $pic = imread($vfile);
#imshow("win", $pic); waitKey(0);
my ($decoded_info,$points,$straight_qrcode,$res) = $qrd->detectAndDecodeMulti($pic);
isa_ok $points, 'PDL', 'detect ok';
#diag $_ for $points,$straight_qrcode;
#diag "code: ", $res;

done_testing();
