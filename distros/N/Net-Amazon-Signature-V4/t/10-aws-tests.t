#!perl

use warnings;
use strict;
use Net::Amazon::Signature::V4;
use File::Slurper 'read_text';
use HTTP::Request;
use Test::More;

my $testsuite_dir = 't/aws4_testsuite';
my @test_names = qw/get-header-key-duplicate get-header-value-order get-header-value-trim get-relative get-relative-relative get-slash get-slash-dot-slash get-slashes get-slash-pointless-dot get-space get-unreserved get-utf8 get-vanilla get-vanilla-empty-query-key get-vanilla-query get-vanilla-query-order-key get-vanilla-query-order-key-case get-vanilla-query-order-value get-vanilla-query-unreserved get-vanilla-ut8-query get-zero post-header-key-case post-header-key-sort post-header-value-case post-vanilla post-vanilla-empty-query-value post-vanilla-query post-vanilla-query-nonunreserved post-vanilla-query-space post-x-www-form-urlencoded post-x-www-form-urlencoded-parameters/; # all tests
# only .req is supplied for test "get-header-value-multiline"; why?

plan tests =>  1+4*@test_names;

my $sig = Net::Amazon::Signature::V4->new(
	'AKIDEXAMPLE',
	'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
	'us-east-1',
	'host',
);

ok( -d $testsuite_dir, 'testsuite directory existence' );

for my $test_name ( @test_names ) {

	ok( -f "$testsuite_dir/$test_name.req", "$test_name.req existence" );
	my $req = HTTP::Request->parse( read_text( "$testsuite_dir/$test_name.req" ) );

	#diag("$test_name creq");
	my $creq = $sig->_canonical_request( $req );
	if ( ! string_fits_file( $creq, "$testsuite_dir/$test_name.creq" ) ) {
		fail( "canonical request mismatch, string-to-sign can't pass" );
		fail( "canonical request mismatch, authorization can't pass" );
		next;
	}

	#diag("$test_name sts");
	my $sts = $sig->_string_to_sign( $req );
	if ( ! string_fits_file( $sts, "$testsuite_dir/$test_name.sts" ) ) {
		fail( "string-to-sign request mismatch, authorization can't pass" );
		next;
	}

	#diag("$test_name authz");
	my $authz = $sig->_authorization( $req );
	string_fits_file( $authz, "$testsuite_dir/$test_name.authz" );
}

sub string_fits_file {
	my ( $str, $expected_path ) = @_;
	my $expected_str = read_text( $expected_path );
	$expected_str =~ s/\r\n/\n/g;
	is( $str, $expected_str, $expected_path );
	return $str eq $expected_str;
}
