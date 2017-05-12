#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Net::SNTP::Server', qw( basicSNTPSetup ) ) || print "Bail out!\n";
}

diag( "Testing Net::SNTP::Server $Net::SNTP::Server::VERSION, Perl $], $^X" );

my %hashInputModuleTest = ( -ip => "127.0.0.1",
			    -port => 12345 );

my %hashInputModuleHostnameTest = ( -ip => undef,
				    -port => 12345 );

my %hashInputModuleUndefPortTest = ( -ip => "127.0.0.1" );

my %hashInputModuleHostnameTestIncompliteIPFirstSegment = ( -ip => ".0.0.1",
							    -port => 12345 );

my %hashInputModuleHostnameTestIncompliteIPSecondSegment = ( -ip => "127..0.1",
							     -port => 12345 );

my %hashInputModuleHostnameTestIncompliteIPThirdSegment = ( -ip => "127.0..1",
							    -port => 12345 );

my %hashInputModuleHostnameTestIncompliteIPFourthSegment = ( -ip => "127.0.0.",
							     -port => 12345 );

my %hashInputModuleTestExtraKeysInserted = ( -ip    => "127.0.0.1",
					     -port        => 12345,
					     -extraKey    => "Test" );

ok( defined( $hashInputModuleTest{-port} ) && $hashInputModuleTest{-port} =~ /\A (\d+) \z/xms , 'Port Has to be Defined and Integer' );

ok( my ( $errorForUndefPort , $hashRefOutputForUndefPort ) = basicSNTPSetup( %hashInputModuleUndefPortTest ), 'Faulty undef Port' );
ok( $errorForUndefPort eq 'Not defined Port', 'Correct Output For Undef Port' );

ok( my ( $errorForUndefHostname , $hashRefOutputForUndefHaustname ) = basicSNTPSetup( %hashInputModuleHostnameTest ), 'Faulty undef Hostname' );
ok( $errorForUndefHostname eq 'Not defined Hostname/IP', 'Correct Output For Undef Hostname' );

ok( my ( $errorForExtraHashKey , $hashRefOutputForExtraHashKey ) = basicSNTPSetup( %hashInputModuleTestExtraKeysInserted ), 'Faulty Test Extra Key' );
ok( $errorForExtraHashKey eq 'Not defined key(s)', 'Correct Output Error Extra Hash Key' );

ok( my ( $errorForFirstSegmentIP , $hashRefOutputForFaultyFirstSegmentIP ) = basicSNTPSetup(  %hashInputModuleHostnameTestIncompliteIPFirstSegment ), 'Faulty 1st segment of IP' );
ok( $errorForFirstSegmentIP eq 'Not correct input IP syntax', 'Correct Output Error First Segment IP Input' );

ok( my ( $errorForSecondSegmentIP , $hashRefOutputForFaultySecondSegmentIP ) = basicSNTPSetup(  %hashInputModuleHostnameTestIncompliteIPSecondSegment ), 'Faulty 2nd segment of IP' );
ok( $errorForSecondSegmentIP eq 'Not correct input IP syntax', 'Correct Output Error Second Segment IP Input' );

ok( my ( $errorForThirdSegmentIP , $hashRefOutputForFaultyThirdSegmentIP ) = basicSNTPSetup(  %hashInputModuleHostnameTestIncompliteIPThirdSegment ), 'Faulty 2nd segment of IP' );
ok( $errorForThirdSegmentIP eq 'Not correct input IP syntax', 'Correct Output Error Third Segment IP Input' );

ok( my ( $errorForFourthSegmentIP , $hashRefOutputForFaultyFourthSegmentIP ) = basicSNTPSetup(  %hashInputModuleHostnameTestIncompliteIPFourthSegment ), 'Faulty 2nd segment of IP' );
ok( $errorForFourthSegmentIP eq 'Not correct input IP syntax', 'Correct Output Error Forth Segment IP Input' );

plan tests => 16;
