#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Net::DHCP::Windows::Netsh::Parse' ) || print "Bail out!\n";
}

my $worked=0;
my $parser;
eval{
	$parser=Net::DHCP::Windows::Netsh::Parse->new;
	if ( ref($parser) eq 'Net::DHCP::Windows::Netsh::Parse' ){
		$worked=1;
	}
};
ok( $worked eq '1', 'init') or diag("Net::DHCP::Windows::Netsh::Parse->new died with ".$@);

my $fh;
my $test_data;
open( $fh, '<', 't/test.data' ) || die( 'failed to open t/test.data' );
read( $fh, $test_data, 40000, 0 ) || die( 'failed to read t/test.data' );
close($fh);

$worked=0;
eval{
	$parser->parse( $test_data );
	$worked=1;
};
ok( $worked eq '1', 'parse') or diag("Net::DHCP::Windows::Netsh::Parse->parse died with ".$@);

if ( defined( $ENV{PERL_MAKE_TEST_DUMP} ) ){
	use Data::Dumper;
	diag( Dumper( $parser ) );
}

ok( $parser->{servers}{'winboot'}{'default'}{'6'}['0'] eq '10.202.97.1', 'parsed default') or diag('failed to parse one or more default options');
ok( $parser->{servers}{'winboot'}{'10.31.145.176'}{'3'}['0'] eq '10.31.145.177', 'parse scope') or diag('failed to parse/add options for the scope 10.31.145.177');
ok( $parser->{servers}{'winboot'}{'10.40.10.0'}{'51'}['0'] eq '1800', 'options 51 junk') or diag('failed to skip junk for option 51 for the scope 10.31.145.177');

$worked=0;
my $json;
eval{
	$json=$parser->json(0);
	if ( defined( $json ) ){
		$worked=1;
	}else{
		$json='';
	}
};
ok( $worked eq '1', 'json') or diag("\$parser->json errored... $@=".$@.'    json='.$json);

$worked=0;
my $hash_ref;
eval{
	$hash_ref=$parser->hash_ref;
	if ( ! defined( $hash_ref ) ){
		die('$hash_ref not defined');
	}
	if ( ! defined( $hash_ref->{'winboot'} ) ){
		die('$hash_ref->{"winboot"} not defined');
	}
	$worked=1;
};
ok( $worked eq '1', 'hash_ref') or diag("\$parser->hash_ref errored... $@=".$@);

done_testing(8);
