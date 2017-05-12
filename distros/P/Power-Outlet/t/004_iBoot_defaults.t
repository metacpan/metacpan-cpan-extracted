# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 18;

BEGIN { use_ok( 'Power::Outlet::iBoot' ); }
BEGIN { use_ok( 'Power::Outlet' ); }

{
  my $outlet=Power::Outlet::iBoot->new;
  isa_ok($outlet, "Power::Outlet::iBoot", "test A1");
  is($outlet->host, "192.168.1.254", "test A2");
  is($outlet->port, "80", "test A3");
  is($outlet->pass, "PASS", "test A4");
}

{
  my $outlet=Power::Outlet->new(type=>"iBoot");
  isa_ok($outlet, "Power::Outlet::iBoot", "test B1");
  is($outlet->host, "192.168.1.254", "test B2");
  is($outlet->port, "80", "test B3");
  is($outlet->pass, "PASS", "test B4");
}

{
  my $outlet=Power::Outlet::iBoot->new(host=>"myhost", port=>"9999", pass=>"mypassword");
  isa_ok($outlet, "Power::Outlet::iBoot", "test C1");
  is($outlet->host, "myhost", "test C2");
  is($outlet->port, "9999", "test C3");
  is($outlet->pass, "mypassword", "test C4");
}

{
  my $outlet=Power::Outlet->new(type=>"iBoot", host=>"myhost", port=>"9999", pass=>"mypassword");
  isa_ok($outlet, "Power::Outlet::iBoot", "test D1");
  is($outlet->host, "myhost", "test D2");
  is($outlet->port, "9999", "test D3");
  is($outlet->pass, "mypassword", "test D4");
}

