# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 22;

BEGIN { use_ok( 'Power::Outlet::iBootBar' ); }
BEGIN { use_ok( 'Power::Outlet' ); }

{
  my $outlet=Power::Outlet::iBootBar->new;
  isa_ok($outlet, "Power::Outlet::iBootBar", "test A1");
  is($outlet->host, "192.168.0.254", "test A2");
  is($outlet->port, "161", "test A3");
  is($outlet->community, "private", "test A4");
  is($outlet->outlet, "1", "test A5");
}

{
  my $outlet=Power::Outlet->new(type=>"iBootBar");
  isa_ok($outlet, "Power::Outlet::iBootBar", "test B1");
  is($outlet->host, "192.168.0.254", "test B2");
  is($outlet->port, "161", "test B3");
  is($outlet->community, "private", "test B4");
  is($outlet->outlet, "1", "test B5");
}

{
  my $outlet=Power::Outlet::iBootBar->new(host=>"myhost", port=>"9999", community=>"mycommunity", outlet=>6);
  isa_ok($outlet, "Power::Outlet::iBootBar", "test C1");
  is($outlet->host, "myhost", "test C2");
  is($outlet->port, "9999", "test C3");
  is($outlet->community, "mycommunity", "test C4");
  is($outlet->outlet, "6", "test C5");
}

{
  my $outlet=Power::Outlet->new(type=>"iBootBar", host=>"myhost", port=>"9999", community=>"mycommunity", outlet=>6);
  isa_ok($outlet, "Power::Outlet::iBootBar", "test D1");
  is($outlet->host, "myhost", "test D2");
  is($outlet->port, "9999", "test D3");
  is($outlet->community, "mycommunity", "test D4");
  is($outlet->outlet, "6", "test D5");
}

