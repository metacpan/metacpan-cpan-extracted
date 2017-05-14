#!/usr/bin/perl

use strict;
use warnings;

use Net::Easypost;
use Net::Easypost::CustomsInfo;
use Net::Easypost::CustomsItem;
use Net::Easypost::Label;
use Net::Easypost::Shipment;
use Test::Exception;
use Test::More tests => 3;

$ENV{EASYPOST_API_KEY} = 'Ao0vbSp2P0cbEhQd8HjEZQ';

if (!eval { require Socket; Socket::inet_aton('www.easypost.com') }) {
    plan skip_all => "Cannot connect to the API server";
}

subtest 'LabelCreationProperties' => sub {
   plan tests => 5;

   my $label = Net::Easypost::Label->new(
      id            => 'pl_X5343',
      tracking_code => '9499907123456123456781',
      url           => 'http://assets.geteasypost.com/.../fake.png',
      filetype      => 'image/png',
      filename      => 'EASYPOST_LABEL_1'
   );

   is( $label->id, 'pl_X5343', 'set id correctly' );
   is( $label->tracking_code, '9499907123456123456781', 'set tracking_code correctly' );
   is( $label->url, 'http://assets.geteasypost.com/.../fake.png', 'set url correctly' );
   is( $label->filetype, 'image/png', 'set filetype correctly' );
   is( $label->filename, 'EASYPOST_LABEL_1', 'set filename correctly' );
};

subtest 'LabelClone' => sub {
   plan tests => 2;

   my $label1 = Net::Easypost::Label->new(
      id            => 'pl_X5343',
      tracking_code => '9499907123456123456781',
      url           => 'http://assets.geteasypost.com/.../fake.png',
      filetype      => 'image/png',
      filename      => 'EASYPOST_LABEL_1'
   );
   my $label2 = $label1->clone;

   is_deeply(
      $label2,
      $label1,
      'Cloned label properties match original'
   );

   ok(
      $label1 != $label2,
      'Cloned label does not have same reference as original'
   );
};

subtest 'LabelSave' => sub {
   plan tests => 2;

   my $to = Net::Easypost::Address->new(
      name    => 'Johnathan Smith',
      street1 => '710 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
      zip     => '22902',
      phone   => '(434)555-5555',
   );

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

   my $customs_info = Net::Easypost::CustomsInfo->new(
       customs_signer   => 'Steve Brule',
       contents_type    => 'merchandise',
       restriction_type => 'none',
       customs_certify  => 1,
       eel_ppc          => 'NOEEI 30.37(a)',
       customs_items => [
	   Net::Easypost::CustomsItem->new(
	       code             => '111111',
	       description	=> 'T-Shirt',
	       quantity		=> 1,
	       weight		=> 5,
	       value		=> 10,
	       hs_tariff_number => '123456',
	       origin_country	=> 'US',
	   )
       ]
   );

   my $shipment = Net::Easypost::Shipment->new(
       to_address   => $to,
       from_address => $from,
       parcel       => $parcel,
       customs_info => $customs_info,
   );

   my $ezpost = Net::Easypost->new(
      access_code => 'Ao0vbSp2P0cbEhQd8HjEZQ'
   );

   my $label = $ezpost->buy_label($shipment, ('rate' => 'lowest'));
   lives_ok {
      $label->save;
   } 'Saving a label lives ok';

   ok(-e $label->filename, 'Label image written correctly');

   # remove label
   unlink $label->filename;
};
