#!/usr/bin/perl

use strict;
use warnings;

use Net::Easypost;
use Net::Easypost::Address;
use Test::Exception;
use Test::More tests => 5;

$ENV{EASYPOST_API_KEY} = 'Ao0vbSp2P0cbEhQd8HjEZQ';

if (!eval { require Socket; Socket::inet_aton('www.easypost.com') }) {
    plan skip_all => "Cannot connect to the API server";
}

subtest 'AddressCreationProperties' => sub {
   plan tests => 4;

   my $address = Net::Easypost::Address->new(
      name    => 'John Smith',
      street1 => '710 East Water Street',
      city    => 'Richmond',
      state   => 'VA',
   );

   # test property setting
   is($address->name, 'John Smith', 'set name correctly');
   is($address->street1, '710 East Water Street', 'set street correctly');
   is($address->city, 'Richmond', 'set city correctly');
   is($address->state, 'VA', 'set state correctly');
};

subtest 'AddressVerificationFailure' => sub {
   plan tests => 1;

   my $address = Net::Easypost::Address->new(
      name    => 'John Smith',
      street1 => '710 East Water Street',
      city    => 'Richmond',
      state   => 'VA',
   );

   throws_ok {
      $address->verify
   } qr/Unable to verify address, failed with message:/,
   'Fake address fails to verify';
};

subtest 'AddressVerificationSuccess' => sub {
   plan tests => 1;

   my $address = Net::Easypost::Address->new(
      name    => 'John Smith',
      street1 => '701 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
   );

   lives_ok {
      $address->verify,
   } 'Real address verifies';
};

subtest 'AddressMerge' => sub {
   plan tests => 1;

   my $address1 = Net::Easypost::Address->new(
      name    => 'John Smith',
      street1 => '701 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
   );

   my $address2 = Net::Easypost::Address->new(
      name    => 'Johnathan Smith',
      street1 => '701 E WATER ST',
      city    => 'Charlottesville',
      state   => 'VA',
      zip     => '22902',
      phone   => '(434)555-5555',
   );

   my $merged_address = Net::Easypost::Address->new(
      name    => 'Johnathan Smith',
      street1 => '701 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
      zip     => '22902',
      phone   => '(434)555-5555',
   );

   is_deeply (
      $address1->merge($address2, [qw(phone name zip)]),
      $merged_address,
      'Merged properties of two addresses correctly'
   );
};

subtest 'AddressClone' => sub {
   plan tests => 2;

   my $address1 = Net::Easypost::Address->new(
      name    => 'John Smith',
      street1 => '710 East Water Street',
      city    => 'Charlottesville',
      state   => 'VA',
   );
   my $address2 = $address1->clone;

   is_deeply (
      $address1,
      $address2,
      'Cloned address properties match original'
   );

   ok (
      $address1 != $address2,
      'Cloned address does not have same reference as original'
   );
};
