#!perl

use strict;
use warnings;

use Test::Most;


use_ok('PayProp::API::Public::Client::Authorization::Storage::Local');

throws_ok
	{ PayProp::API::Public::Client::Authorization::Storage::Local->new }
	qr{Attribute \(encryption_secret\) is required}
;

isa_ok(
	my $Local = PayProp::API::Public::Client::Authorization::Storage::Local->new(
		encryption_secret => 'bleh blurp berp',
		throw_on_storage_unavailable => 1,
	),
	'PayProp::API::Public::Client::Authorization::Storage::Local'
);

subtest '_ping_p' => sub {

	$Local
		->_ping_p
		->then( sub {
			my ( $ping_value ) = @_;

			is $ping_value, 1;
		} )
		->wait
	;

};

subtest '_set_p' => sub {

	$Local
		->_set_p( 'test_key', 'test_value' )
		->then( sub {
			my ( $ok ) = @_;

			is $ok, 1;
		} )
		->wait
	;

};

subtest '_get_p' => sub {

	$Local
		->_get_p('test_key')
		->then( sub {
			my ( $value ) = @_;

			is $value, 'test_value';
		} )
		->wait
	;

};

subtest '_delete_p' => sub {

	$Local
		->_delete_p('test_key')
		->then( sub {
			my ( $ok ) = @_;

			is $ok, 1;
		} )
		->wait
	;

	is scalar keys $Local->storage->%*, 0, 'no keys';

};

done_testing;
