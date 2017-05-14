#!/usr/bin/perl

use strict;
use Test::More tests => 13;

use Net::Easypost;
use Net::Easypost::Address;
use Net::Easypost::Parcel;
use Net::Easypost::Rate;

$ENV{EASYPOST_API_KEY} = 'Ao0vbSp2P0cbEhQd8HjEZQ';

if (!eval { require Socket; Socket::inet_aton('www.easypost.com') }) {
    plan skip_all => "Cannot connect to the API server";
}

# 60 second connection timeout
$ENV{MOJO_CONNECT_TIMEOUT} = 60;

my $ezpost = Net::Easypost->new;
isa_ok($ezpost, 'Net::Easypost', 'object created');

my $addr = $ezpost->verify_address(
   {  street1 => '388 Townsend St',
      street2 => 'Apt 20',
      city    => 'San Francisco',
      zip     => '94107',
      name    => 'Zaphod',
   }
);

is($addr->state, 'CA', 'got right state');
is($addr->name, 'Zaphod', 'name copied');
like(sprintf($addr), qr/Zaphod\n/xms, 'address stringified');

my $rates = $ezpost->get_rates(
   to =>
      Net::Easypost::Address->new(
         name    => 'Hunter M',
         street1 => '701 E Water St',
         city    => 'Charlottesville',
         zip     => '22902'
      ),
   from =>
      Net::Easypost::Address->new(
         name    => 'Sydney S',
         street1 => '117 Altamont Circle',
         city    => 'Charlottesville',
         zip     => '22902'
      ),
   parcel =>
      Net::Easypost::Parcel->new(
         length => 10.0,
         width  => 5.0,
         height => 8.0,
         weight => 100.0
      )
);

cmp_ok(scalar @$rates, '>=', 3, 'got more than 1 rates');
isa_ok($rates->[0], 'Net::Easypost::Rate', 'element correctly');
like($rates->[0]->carrier, qr/USPS|UPS|FedEx/, 'carrier is correct');

$addr->name('Jon Calhoun');
my $to = $addr->clone;

my $from = Net::Easypost::Address->new(
   name    => 'Jarrett Streebin',
   phone   => '3237078576',
   city    => 'Half Moon Bay',
   street1 => '310 Granelli Ave',
   state   => 'CA',
   zip     => '94019',
);

my $parcel = Net::Easypost::Parcel->new(
   length => 10.0,
   width  => 5.0,
   height => 8.0,
   weight => 10.0,
);

my $shipment = Net::Easypost::Shipment->new(
   to_address   => $to,
   from_address => $from,
   parcel       => $parcel,
);
my $label = $ezpost->buy_label($shipment, service_type => 'Priority');

ok($label->has_url, 'has url!');
ok( !$label->has_image, 'has no image');
like($label->filename, qr/\.png/, 'got png again!');
like($label->tracking_code, qr/[0-9]+/, 'got correct test tracking code');
$label->save;
ok($label->has_image, 'has image');
ok(-e $label->filename, 'image file exists');

unlink $label->filename;
