#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Encrypt;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Encrypt /;

	1;
}

throws_ok { Test::Role::Encrypt->new } qr{Attribute \(encryption_secret\) is required};

isa_ok(
	my $Encrypt = Test::Role::Encrypt->new( encryption_secret => 'beh blurp heump' ),
	'Test::Role::Encrypt',
);

my $encrypted;
my $to_encrypt = 'bleh_blurp#/23d.Oe_';

subtest '->encrypt_hex_p' => sub {

	$Encrypt
		->encrypt_hex_p( $to_encrypt )
		->then( sub {
			( $encrypted ) = @_;

			isnt $encrypted, $to_encrypt, 'encrypted string not equal to initial string';
			like $encrypted, qr/[a-z0-9]/, '[a-z0-9]';
		} )
		->wait
	;

};

subtest '->decrypt_hex_p' => sub {

	$Encrypt
		->decrypt_hex_p( $encrypted )
		->then( sub {
			my ( $decrypted ) = @_;

			is $decrypted, $to_encrypt, 'decrypted string equal to initial value';
		} )
		->wait
	;

};

done_testing;
