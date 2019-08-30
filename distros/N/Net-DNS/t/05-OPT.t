# $Id: 05-OPT.t 1754 2019-08-19 14:12:28Z willem $	-*-perl-*-

use strict;
use Test::More;

use Net::DNS;
use Net::DNS::Parameters;


plan tests => 33 + scalar( keys %Net::DNS::Parameters::ednsoptionbyval );


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
	local $SIG{__WARN__} = sub { die @_ };

	eval { $rr->$method(512) };
	my ($warning) = split /\n/, "$@\n";
	ok( 1, "deprecated $method method:\t[$warning]" );	# warning may, or may not, be first

	eval { $rr->$method(512) };
	my ($repeated) = split /\n/, "$@\n";
	ok( !$repeated, "warning not repeated\t[$repeated]" );
}


{
	my $rr = new Net::DNS::RR( name => '.', type => $type, version => 1, rcode => 16 );
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


	foreach my $option ( keys %Net::DNS::Parameters::ednsoptionbyval ) {
		$edns->option( $option => 'rawbytes' );
	}


	$edns->option( 4 => '' );
	is( length( $edns->option(4) ), 0, "option 4 => ''" );

	$edns->option( DAU => [5, 7, 8, 10] );
	is( length( $edns->option(5) ), 4, "option DAU => [5, 7, 8, 10]" );

	$edns->option( 10 => {'CLIENT-COOKIE' => 'rawbytes'} );
	is( length( $edns->option(10) ), 8, "option 10 => {CLIENT-COOKIE => ... }" );


	$edns->option( 5 => pack 'H*', '0507080A0D0E0F10' );

	$edns->option( 6 => pack 'H*', '010204' );

	$edns->option( 7 => pack 'H*', '01' );

	$edns->option( 8 => ( pack 'H*', '000117007b7b7a' ) );

	$edns->option( 9 => pack 'H*', '00093A80' );

	$edns->option( 10 => pack 'H*', '7261776279746573636f6f6b65646279746573' );

	$edns->option( 11 => pack 'H*', '00C8' );

	$edns->option( 12 => pack 'x100' );

	$edns->option( 13 => pack 'H*', '03636F6D00' );

	$edns->option( 15 => pack 'H*', '007B' );


	foreach my $option ( sort { $a <=> $b } keys %Net::DNS::Parameters::ednsoptionbyval ) {
		my $content = $edns->option($option);		# check option interpretation

		my @interpretation = $edns->option($option);
		$edns->option( $option => (@interpretation) );

		my $uninterpreted = $edns->option($option);
		is( $uninterpreted, $content, "compose/decompose option $option" );
	}


	eval { $edns->option( 65001 => ( '', '' ) ) };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unable to compose option:\t[$exception]" );


	my $options = $edns->options;
	my $encoded = $edns->encode;
	my $decoded = decode Net::DNS::RR( \$encoded );
	my @result  = $decoded->options;
	is( scalar(@result), $options, 'expected number of options' );

	$edns->print;
}


exit;

