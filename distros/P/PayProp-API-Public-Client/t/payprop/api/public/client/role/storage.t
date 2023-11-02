#!perl

use strict;
use warnings;

use Test::Most;


throws_ok
	{
		{
			package Test::Role::BadStorage;
			use Mouse;
			with qw/ PayProp::API::Public::Client::Role::Storage /;
			1;
		};

		Test::Role::BadStorage->new;
	}
	qr/requires the methods .*? to be implemented/
;

{
	package Test::Role::Storage;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Storage /;

	sub _set_p {}
	sub _get_p {}
	sub _ping_p {}
	sub _delete_p {}

	1;
}

isa_ok(
	my $Storage = Test::Role::Storage->new( encryption_secret => 'blurp' ),
	'Test::Role::Storage',
);

is $Storage->cache_prefix, 'PayPropAPIToken_', '->cache_prefix';
is $Storage->cache_ttl_in_seconds, 43200, '->cache_ttl_in_seconds';

subtest '->_handle_exception' => sub {

	isa_ok(
		my $TestStorageThrows = Test::Role::Storage->new(
			encryption_secret => 'testbananabananabanana',
			throw_on_storage_unavailable => 1,
		),
		'Test::Role::Storage'
	);

	throws_ok
		{ $TestStorageThrows->_handle_exception() }
		qr{UNKKNOWN STORAGE ERROR}
	;

};

done_testing;
