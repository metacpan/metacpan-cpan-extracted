#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Attribute::Storage;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Attribute::Storage /;

	has '+storage_key' => ( default => 'meh' );

	1;
}

throws_ok
	{ Test::Role::Attribute::Storage->new( storage => 'badbad' ) }
	qr/Attribute \(storage\) does not pass the type constraint/
;

throws_ok
	{ Test::Role::Attribute::Storage->new->storage }
	qr/storage not implemented/
;

isa_ok(
	Test::Role::Attribute::Storage
		->new( storage => bless( {}, 'PayProp::API::Public::Client::Authorization::Storage::Memcached' ) )
		->storage,
	'PayProp::API::Public::Client::Authorization::Storage::Memcached'
);

done_testing;
