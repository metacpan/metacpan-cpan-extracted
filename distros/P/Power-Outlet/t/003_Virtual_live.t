# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 2 + 13 * 4;

BEGIN { use_ok( 'Power::Outlet::Virtual' ); }

{
  my $uuid = '681acdb8-453d-11eb-b77a-0011955df2b5';
  my $device = Power::Outlet::Virtual->new(_folder=>$uuid);
  local $@;
  my $folder = eval{$device->_folder}; #die if not writable
  my $error  = $@;
  like($error, qr{Directory .*$uuid.* is not writable}, '_folder writable');
}

foreach my $id (1, '123', 'with space', 'with:colon') {
  my $device = Power::Outlet::Virtual->new(id=>$id);
  isa_ok ($device, 'Power::Outlet::Virtual');
  is($device->id, $id, 'id');
  local $@;
  my $folder = eval{$device->_folder}; #die if not writable
  my $error  = $@;
  SKIP: {
    skip $error, 11 if $error;
    my $state  = $device->query;
    if ($state eq "ON") {
      diag("Turning Off");
      $device->off;
    }

    diag("Turning On");
    is($device->on, "ON", 'on method');
    is($device->query, "ON", 'query method');

    diag("Turning Off");
    is($device->off, "OFF", 'off method');
    is($device->query, "OFF", 'query method');

    diag("Switching");
    is($device->switch, "ON", 'on method');
    is($device->query, "ON", 'query method');

    diag("Switching");
    is($device->switch, "OFF", 'off method');
    is($device->query, "OFF", 'query method');

    diag("Cycling");
    is($device->cycle, "OFF", 'cycle method');
    is($device->query, "OFF", 'query method');

    is($device->query, "OFF", 'query method');

    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}
