#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Deep;

#########################

BEGIN { use_ok( 'Net::SNTP::Client', qw( getSNTPTime ) ) || print "Bail out!\n"; }

diag( "Testing Net::SNTP::Client $Net::SNTP::Client::VERSION, Perl $], $^X" );

my %hashInputModuleHostnameTest = ( -hostname => undef );

my %hashInputModuleTest = ( -hostname    => "0.europe.pool.ntp.org",
			    -port        => 123 );

my %hashInputModuleTestExtraKeysInserted = ( -hostname    => "0.europe.pool.ntp.org",
					     -port        => 123,
					     -timeOut  => 15,
					     -RFC4330     => 1,
					     -clearScreen => 1,
					     -extraKey    => "Test" );

my %hashInputModuleTestNoHostName = ( -port        => 123,
				      -timeOut  => 15,
				      -RFC4330     => 1,
				      -clearScreen => 1 );

my %hashInputModuleTestNegativePortNumber = ( -hostname    => "0.europe.pool.ntp.org",
					      -port        => -123,
					      -timeOut  => 15,
					      -RFC4330     => 1,
					      -clearScreen => 1 );

my %hashInputModuleTestNegativeTimeOutNumber = ( -hostname    => "0.europe.pool.ntp.org",
						 -port        => 123,
						 -timeOut  => -15,
						 -RFC4330     => 1,
						 -clearScreen => 1 );

my %hashInputModuleTestOutOfRangePortNumber = ( -hostname    => "0.europe.pool.ntp.org",
						-port        => 65537,
						-timeOut  => 15,
						-RFC4330     => 1,
						-clearScreen => 1 );

my %hashInputModuleTestFloatingPortNumber = ( -hostname    => "0.europe.pool.ntp.org",
					      -port        => 1.23,
					      -timeOut  => 15,
					      -RFC4330     => 1,
					      -clearScreen => 1 );

my %hashInputModuleTestNotCorrectNtpPortNumber = ( -hostname    => "0.europe.pool.ntp.org",
						   -port        => 12345,
						   -timeOut  => 15,
						   -RFC4330     => 1,
						   -clearScreen => 1 );

my %hashInputModuleTestFaultyRFC4330Input = ( -hostname    => "0.europe.pool.ntp.org",
					      -port        => 123,
					      -RFC4330     => "Faulty Input Test");

my %hashInputModuleTestFaultyClearScreenInput = ( -hostname    => "0.europe.pool.ntp.org",
						  -port        => 123,
						  -clearScreen     => "Faulty Input Test");

my @hashInputModuleTestOriginalKeys = ( "-hostname" , "-port", "-timeOut", "-RFC4330", "-clearScreen" );

my $hashRefExpected = {
    'RFC4330' => {
	'Round Trip Delay' => ignore(),
	    'Clock Offset' => ignore(),
    },
	'0.europe.pool.ntp.org' => {
	    'Transmit Timestamp' => ignore(),
		'Precision' => ignore(),
		'Receive Timestamp' => ignore(),
		'VN' => ignore(),
		'Reference Identifier' => ignore(),
		'Originate Timestamp' => ignore(),
		'Mode' => ignore(),
		'Reference Timestamp' => ignore(),
		'Stratum' => ignore(),
		'Poll' => ignore(),
		'Root Dispersion' => ignore(),
		'LI' => ignore(),
		'Root Delay' => ignore(),
    },
	't/00-load.t' => {
	    'Root Delay' => ignore(),
		'LI' => ignore(),
		'Root Dispersion' => ignore(),
		'Stratum' => ignore(),
		'Poll' => ignore(),
		'Reference Timestamp' => '0.0',
		'Mode' => ignore(),
		'Originate Timestamp' => '0.0',
		'Reference Identifier' => ignore(),
		'Transmit Timestamp' => ignore(),
		'Receive Timestamp' => ignore(),
		'VN' => 4,
		'Precision' => ignore(),
    }
};

ok( getSNTPTime( %hashInputModuleTest ), 'Module Hash Input Works' );

ok( my ( $errorForUndefHostname , $hashRefOutputForUndefHaustname ) =
    getSNTPTime( %hashInputModuleHostnameTest ),
    'Faulty undef Hostname' );

ok( $errorForUndefHostname eq 'Not defined Hostname/IP', 'Correct Output For Undef Hostname' );

ok( defined( $hashInputModuleTest{-port} ) && $hashInputModuleTest{-port} =~ /\A (\d+) \z/xms , 'Port Has to be Defined and Integer' );
ok( my ( $error , $hashRefOutput ) =
    getSNTPTime( %hashInputModuleTest ),
    'Got Hash Output' );

my @expectedHashKeys = (sort {lc $a cmp lc $b} keys %{ $hashRefExpected });
my @gotHashRefKeys = (sort {lc $a cmp lc $b} keys %{ $hashRefOutput });

SKIP: {
    skip 'No Internet Connection...', 2, if $error;
    is_deeply( [sort @gotHashRefKeys], [sort @expectedHashKeys], 'Module Hash Keys are Identical' );
    cmp_deeply( $hashRefOutput, $hashRefExpected, 'Exptected Output From the Module Received' );
}

ok( my ( $errorForExtraHashKey , $hashRefOutputForExtraHashKey ) =
    getSNTPTime( %hashInputModuleTestExtraKeysInserted ),
    'Faulty Test Extra Key' );
ok( $errorForExtraHashKey eq 'Not defined key(s)', 'Correct Output Error Extra Hash Key' );

ok( my ( $errorNoHostname , $hashRefOutputNoHostName ) =
    getSNTPTime( %hashInputModuleTestNoHostName ),
    'Faulty Test no Hostname' );

ok( $errorNoHostname eq 'Not defined Hostname/IP', 'Correct Output Error No Hostname' );

ok( my ( $errorNegativePortNumber , $hashRefOutputNegativePortNumber ) =
    getSNTPTime( %hashInputModuleTestNegativePortNumber ),
    'Faulty Test Negative Port Number' );
ok( $errorNegativePortNumber eq 'Not correct port number', 'Correct Output Error for Negative Port Number' );

ok( my ( $errorNegativeTimeOutInputNumber , $hashRefOutpoutNegativeTimeOutInputNumber ) = 
    getSNTPTime( %hashInputModuleTestNegativeTimeOutNumber ),
    'Faulty Test Negative TimeOutInput Number' );
ok( $errorNegativeTimeOutInputNumber eq 'Not correct timeOut input', 'Correct Output Error for Negative TimeOutInput Number' );

ok( my ( $errorOutOfRangePortNumber , $hashRefOutputOutOfRangePortNumber ) =
    getSNTPTime( %hashInputModuleTestOutOfRangePortNumber ),
    'Faulty Test Out of Range Port Number' );
ok( $errorOutOfRangePortNumber eq 'Not correct port number', 'Correct Output Error Out of Range Port Number' );

ok( my ( $errorFloatingPortNumber , $hashRefOutputFloatingPortNumber ) =
    getSNTPTime( %hashInputModuleTestFloatingPortNumber ),
    'Faulty Test Floating Port Number' );
ok( $errorFloatingPortNumber eq 'Not correct port number', 'Correct Output Error Out of Floating Port Number' );

ok( my ( $errorFaultyRFC4330Input , $hashRefOutputFaultyRFC4330Input ) =
    getSNTPTime( %hashInputModuleTestFaultyRFC4330Input ),
    'Faulty Test wrong input string at RFC4330' );
ok( $errorFaultyRFC4330Input eq 'Not correct RFC4330 input', 'Correct Output Error RFC4330 Faulty Input' );

ok( my ( $errorFaultyClearScreenInput , $hashRefOutputFaultyClearScreenInput ) = 
    getSNTPTime( %hashInputModuleTestFaultyClearScreenInput ),
    'Faulty Test wrong input string at RFC4330' );
ok( $errorFaultyClearScreenInput eq 'Not correct clearScreen input', 'Correct Output Error clearScreen Faulty Input' );

plan tests => 24;
