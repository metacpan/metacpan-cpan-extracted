#!/usr/bin/perl
# $Id: 05-OPT.t 1887 2022-12-20 14:39:53Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS;
use Net::DNS::Parameters;
use Net::DNS::RR::OPT;


my @options = keys %Net::DNS::Parameters::ednsoptionbyval;

plan tests => 28 + scalar(@options);


my $name = '.';
my $type = 'OPT';
my $code = 41;
my @attr = qw( version size rcode flags );
my @data = qw( 0 1280 0 32768 );
my @also = ();

my $wire = '0000290500000080000000';


{
	my $typecode = unpack 'xn', Net::DNS::RR->new( name => '.', type => $type )->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = Net::DNS::RR->new(
		name => $name,
		type => $type,
		%$hash
		);

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		my $value = $rr->$_;
		ok( defined $rr->$_, "additional attribute rr->$_()" );
	}

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = uc unpack 'H*', $encoded;
	my $hex2    = uc unpack 'H*', $decoded->encode;
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex1, $wire, 'encoded RDATA matches example' );
}


{
	my $rr = Net::DNS::RR->new( name => '.', type => $type );
	foreach (@attr) {
		my $initial = 0x5A5;
		my $changed = 0xA5A;
		$rr->{$_} = $initial;
		is( $rr->$_($changed), $changed, "rr->$_(x) returns function argument" );
		is( $rr->$_(),	       $changed, "rr->$_()  returns changed value" );
	}

	$rr->version(1);
	like( $rr->string, '/EDNS/', 'string method works' );
}


foreach my $method (qw(class ttl)) {
	my $rr = Net::DNS::RR->new( name => '.', type => $type );
	local $SIG{__WARN__} = sub { die @_ };

	eval { $rr->$method(512) };
	my ($warning) = split /\n/, "$@\n";
	ok( 1, "deprecated $method method\t[$warning]" );	# warning may, or may not, be first

	eval { $rr->$method(512) };
	my ($repeated) = split /\n/, "$@\n";
	ok( !$repeated, "warning not repeated\t[$repeated]" );
}


{
	my $packet = Net::DNS::Packet->new(qw(example A));
	my $edns   = $packet->edns;

	ok( ref($edns), 'new OPT RR created' );

	is( scalar( $edns->options ), 0, 'EDNS option list initially empty' );

	my $non_existent = $edns->option(0);
	is( $non_existent, undef, '$undef = option(0)' );

	ok( !$edns->_specified, 'state unmodified by existence probes' );

	$edns->option( 0 => '' );
	is( scalar( $edns->options ), 1, 'insert EDNS option' );

	$edns->option( 0 => undef );
	is( scalar( $edns->options ), 0, 'delete EDNS option' );


	foreach my $option (@options) {
		$edns->option( $option => ( '00', [0] ) );	# exercise list expansion
		$edns->option( $option => {'OPTION-DATA' => 'rawbytes'} );
	}


	$edns->option( 1 => {'OPTION-DATA' => pack( 'n@18', 1 )} );	     # deprecated option

	$edns->option( 4 => '' );

	$edns->option( 5 => [8, 10, 13, 14, 15, 16] );

	$edns->option( 6 => [1, 2, 4] );

	$edns->option( 7 => [] );

	$edns->option( 8 => {'FAMILY' => 99} );
	$edns->option( 8 => {'BASE16' => '00990000'} );
	my @option8 = $edns->option(8);
	$edns->option( 8 => {'BASE16' => '0002380020010db8fd1342'} );

	$edns->option( 9 => {'OPTION-LENGTH' => 0} );		# per RFC7314
	my @option9 = $edns->option(9);
	$edns->option( 9 => {'EXPIRE-TIMER' => 604800} );

	$edns->option( 11 => {'OPTION-LENGTH' => 0} );		# per RFC7828
	my @option11 = $edns->option(11);
	$edns->option( 11 => {'TIMEOUT' => 200} );

	my @option12 = $edns->option(12);			# non-zero content
	$edns->option( 12 => {'LENGTH' => 100} );		# zero content per RFC7830

	$edns->option( 13 => {'BASE16' => '076578616d706c6500'} );

	$edns->option( 15 => {'INFO-CODE' => 123} );

	$edns->option( 65023 => {'BASE16' => '076578616d706c6500'} );

	foreach my $option ( sort { $a <=> $b } @options ) {
		my $uninterpreted  = unpack 'H*', $edns->option($option);
		my @interpretation = $edns->option($option);	# check option interpretation
		$edns->option( $option => @interpretation );
		my $reconstituted = unpack 'H*', $edns->option($option);
		is( "$reconstituted", "$uninterpreted", "compose/decompose option $option" );
	}


	eval { $edns->option( 65001 => [] ) };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unable to compose option:\t[$exception]" );


	my $options = $edns->options;
	my $encoded = $edns->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my @result  = $decoded->options;
	is( scalar(@result), $options, 'expected number of options' );

local $Net::DNS::Parameters::ednsoptionbyval{65023};
	$edns->print;
}


exit;

