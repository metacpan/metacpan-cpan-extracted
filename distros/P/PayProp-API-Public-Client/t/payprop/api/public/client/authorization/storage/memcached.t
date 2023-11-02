#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Authorization::Storage::Memcached');

throws_ok
	{ PayProp::API::Public::Client::Authorization::Storage::Memcached->new }
	qr{Attribute \(encryption_secret\) is required}
;

throws_ok
	{ PayProp::API::Public::Client::Authorization::Storage::Memcached->new( encryption_secret => 'meh' ) }
	qr{Attribute \(servers\) is required}
;

subtest 'Memcached - No server available; throw on connection failure' => sub {

	isa_ok(
		my $Memcached = PayProp::API::Public::Client::Authorization::Storage::Memcached->new(
			servers => [ '127.0.0.1:0' ],
			encryption_secret => 'bleh blurp berp',
			throw_on_storage_unavailable => 1,
		),
		'PayProp::API::Public::Client::Authorization::Storage::Memcached'
	);

	$Memcached
		->_ping_p
		->catch( sub {
			my ( $exception ) = @_;

			like "$exception", qr/ping failed/;
		} )
		->wait
	;

};

subtest 'Memcached - Server (maybe?) is available; if so, run CRUDs' => sub {

	my $servers = [ '127.0.0.1:11211', 'memcached:11211' ];

	isa_ok(
		my $Memcached = PayProp::API::Public::Client::Authorization::Storage::Memcached->new(
			servers => $servers,
			encryption_secret => 'bleh blurp berp',
		),
		'PayProp::API::Public::Client::Authorization::Storage::Memcached'
	);

	SKIP: {

		my $can_connect_to_memcached;
		my $number_of_tests_to_skip = 4;
		my $servers_str = join ', ', $servers->@*;

		$Memcached
			->_ping_p
			->then( sub { $can_connect_to_memcached = 1 } )
			->wait
		;

		skip "Could not connect to any memcached server on - $servers_str", $number_of_tests_to_skip
			unless $can_connect_to_memcached
		;

		subtest '_ping_p' => sub {

			$Memcached
				->_ping_p
				->then( sub {
					my ( $ping_value ) = @_;

					is $ping_value, 'pong';
				} )
				->wait
			;

		};

		subtest '_set_p' => sub {

			$Memcached
				->_set_p( 'test_key', 'test_value' )
				->then( sub {
					my ( $ok ) = @_;

					is $ok, 1;
				} )
				->wait
			;

		};

		subtest '_get_p' => sub {

			$Memcached
				->_get_p('test_key')
				->then( sub {
					my ( $value ) = @_;

					is $value, 'test_value';
				} )
				->wait
			;

		};

		subtest '_delete_p' => sub {

			$Memcached
				->_delete_p('test_key')
				->then( sub {
					my ( $ok ) = @_;

					is $ok, 1;
				} )
				->wait
			;

		};

	};

};

done_testing;
