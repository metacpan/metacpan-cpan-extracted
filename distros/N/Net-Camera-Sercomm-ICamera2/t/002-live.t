# -- perl --
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('Net::Camera::Sercomm::ICamera2') };

my $hostname = $ENV{'NET_CAMERA_SERCOMM_ICAMERA2_HOSTNAME'};

SKIP: {
  skip 'export NET_CAMERA_SERCOMM_ICAMERA2_HOSTNAME not set', 3 unless $hostname;
  my $cam    = Net::Camera::Sercomm::ICamera2->new(hostname => $hostname);
  isa_ok($cam, 'Net::Camera::Sercomm::ICamera2');

  my $jpeg   = $cam->getSnapshot;
  my $length = length($jpeg);
  ok($length > 1000, "length: $length");
  like($jpeg, qr/\A\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01/, 'JPEG majic number');
}
