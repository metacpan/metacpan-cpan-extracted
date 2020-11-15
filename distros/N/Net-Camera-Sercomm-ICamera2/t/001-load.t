# -- perl --
use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('Net::Camera::Sercomm::ICamera2') };
my $cam = Net::Camera::Sercomm::ICamera2->new;
isa_ok($cam, 'Net::Camera::Sercomm::ICamera2');
can_ok($cam, 'new');
can_ok($cam, 'getSnapshot');

