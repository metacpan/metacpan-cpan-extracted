# $Id: 05-OPT.t 1543 2017-02-28 19:27:23Z willem $	-*-perl-*-

use strict;
use Test::More;

use Net::DNS;
use Net::DNS::Parameters;

my @opt = keys %Net::DNS::Parameters::ednsoptionbyval;

plan tests => 42 + scalar(@opt);


my $name = '.';
my $type = 'OPT';
my $code = 41;
my @attr = qw( size rcode flags );
my @data = qw( 1280 0 32768 );
my @also = qw( version );

my $wire = '0000290500000080000000';


{
	my $typecode = unpack 'xn', new Net::DNS::RR( name => '.', type => $type )->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = new Net::DNS::RR(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	like( $string, '/EDNS/', 'string method works' );

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		my $value = $rr->$_;
		ok( defined $rr->$_, "additional attribute rr->$_()" );
	}

	my $encoded = $rr->encode;
	my $decoded = decode Net::DNS::RR( \$encoded );
	my $hex1    = uc unpack 'H*', $encoded;
	my $hex2    = uc unpack 'H*', $decoded->encode;
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex1, $wire, 'encoded RDATA matches example' );
}


{
	my $rr = new Net::DNS::RR( name => '.', type => $type );
	foreach (@attr) {
		my $initial = 0x5A5;
		my $changed = 0xA5A;
		$rr->{$_} = $initial;
		is( $rr->$_($changed), $changed, "rr->$_(x) returns function argument" );
		is( $rr->$_(),	       $changed, "rr->$_(x) changes attribute value" );
	}
}


foreach my $method (qw(class ttl)) {
	my $rr = new Net::DNS::RR( name => '.', type => $type );
	eval {
		local $SIG{__WARN__} = sub { die @_ };
		$rr->$method(1);
	};
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "$method method:\t[$exception]" );

	eval {
		local $SIG{__WARN__} = sub { die @_ };
		$rr->$method(0);
	};
	my $repeated = $1 if $@ =~ /^(.+)\n/;
	ok( !$repeated, "$method exception not repeated $@" );
}


{
	my $rr = new Net::DNS::RR( name => '.', type => $type, rcode => 16 );
	$rr->{rdlength} = 0;					# inbound OPT RR only
	like( $rr->string, '/BADVER/', 'opt->rcode(16)' );
}


{
	my $rr = new Net::DNS::RR( name => '.', type => $type, rcode => 1 );
	like( $rr->string, '/NOERROR/', 'opt->rcode(1)' );
}


{
	my $edns = new Net::DNS::RR( name => '.', type => $type );

	ok( ref($edns), 'new OPT RR created' );

	is( scalar( $edns->options ), 0, 'EDNS option list initially empty' );

	ok( !$edns->_format_option(0), 'format non-existent option(0)' );

	my $non_existent = $edns->option(0);
	is( $non_existent, undef, '$undef = option(0)' );

	my @non_existent = $edns->option(0);
	is( scalar(@non_existent), 0, '@empty = option(0)' );

	ok( !$edns->_specified, 'state unmodified by existence probes' );

	$edns->option( 0 => '' );
	is( scalar( $edns->options ), 1, 'insert EDNS option' );

	$edns->option( 0 => undef );
	is( scalar( $edns->options ), 0, 'delete EDNS option' );


	foreach my $option ( sort { $a <=> $b } keys %Net::DNS::Parameters::ednsoptionbyval ) {
		$edns->option( $option => 'rawbytes' );
	}


	$edns->option( 4 => '' );
	is( length( $edns->option(4) ), 0, "option 4 => ''" );


	$edns->option( DAU => [1, 2, 3, 4] );
	is( length( $edns->option(5) ), 4, 'option DAU => (1, 2, 3, 4)' );


	$edns->option( 8 => ( pack 'H*', '000120007b7b7b7b' ) );
	my %option8 = $edns->option(8);
	$edns->option( 'CLIENT-SUBNET' => (%option8) );
	is( length( $edns->option(8) ), 8, "option CLIENT-SUBNET => (%option8)" );
	$edns->option( 'CLIENT-SUBNET' => {%option8, 'SOURCE-PREFIX-LENGTH' => 15} );
	is( length( $edns->option(8) ), 6, "option CLIENT-SUBNET => {'SOURCE-PREFIX-LENGTH' => 15, ...}" );


	my $timer = 604800;
	my $option9 = $edns->option( EXPIRE => ( 'EXPIRE-TIMER' => $timer ) );
	is( scalar( $edns->option(9) ), $option9, "option EXPIRE => ('EXPIRE-TIMER' => $timer)" );


	my $client = $edns->option( COOKIE => ( 'CLIENT-COOKIE' => 'rawbytes' ) );
	is( length( $edns->option(10) ), 8, "option COOKIE => ('CLIENT-COOKIE' => ... )" );

	my %option10 = $edns->option(10);
	$edns->option( COOKIE => {%option10, 'SERVER-COOKIE' => 'cookedbytes'} );
	is( length( $edns->option(10) ), 19, "option COOKIE => {'SERVER-COOKIE' => ... }" );


	my $t = 200;
	my $option11 = $edns->option( 'TCP-KEEPALIVE' => ( TIMEOUT => $t ) );
	is( scalar( $edns->option(11) ), $option11, "option TCP-KEEPALIVE => (TIMEOUT => $t)" );


	$edns->option( PADDING => ( 'OPTION-LENGTH' => 100 ) );
	is( length( $edns->option(12) ), 100, "option PADDING => ('OPTION-LENGTH' => 100)" );


	$edns->option( CHAIN => ( 'TRUST-POINT' => '' ) );
	is( length( $edns->option(13) ), 0, "option CHAIN => ''" );

	my $option13 = $edns->option( CHAIN => ( 'TRUST-POINT' => 'com.' ) );
	is( scalar( $edns->option(13) ), $option13, "option CHAIN => ('TRUST-POINT' => 'com.')" );


	foreach my $option ( sort { $a <=> $b } keys %Net::DNS::Parameters::ednsoptionbyval ) {
		my $content = $edns->option($option);		# check option interpretation

		my @interpretation = $edns->option($option);
		$edns->option( $option => (@interpretation) );

		my $uninterpreted = $edns->option($option);
		is( $uninterpreted, $content, "compose/decompose option $option" );
	}


	eval { $edns->option( 65001 => ( '', '' ) ) };
	chomp $@;
	ok( $@, "unable to compose option:\t[$@]" );


	my $bogus = 'BOGUS-OPTION';
	eval { ednsoptionbyname($bogus) };
	chomp $@;
	ok( $@, "ednsoptionbyname($bogus)\t[$@]" );


	my $options = $edns->options;
	my $encoded = $edns->encode;
	my $decoded = decode Net::DNS::RR( \$encoded );
	my @result  = $decoded->options;
	is( scalar(@result), $options, 'expected number of options' );

	$edns->print;
}


exit;

