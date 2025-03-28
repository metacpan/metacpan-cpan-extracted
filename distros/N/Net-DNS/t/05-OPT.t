#!/usr/bin/perl
# $Id: 05-OPT.t 1996 2024-12-16 13:05:08Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 89;
use TestToolkit;

use Net::DNS;
use Net::DNS::Parameters;

use constant UTIL => scalar eval { require Scalar::Util; Scalar::Util->can('isdual') };	## no critic


my $code = 41;
my $type = 'OPT';
my @attr = qw( version udpsize rcode flags );
my $wire = '0000290000000000000000';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );


for my $edns ( Net::DNS::Packet->new()->edns ) {
	my $encoded = $edns->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = uc unpack 'H*', $encoded;
	my $hex2    = uc unpack 'H*', $decoded->encode;
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex1, $wire, 'encoded RDATA matches example' );

	like( $edns->string, '/EDNS-VERSION/', '$edns->string works' );

	$edns->rdata( pack 'H*', '00040002beef' );
	like( $edns->plain, '/TYPE41/', '$edns->generic works' );    # join token(generic)

	$edns->version(1);
	like( $edns->string, '/EDNS-VERSION/', '$edns->string (version 1)' );

	foreach (@attr) {
		my $changed = 0xbeef;
		is( $edns->$_($changed), $changed, "edns->$_(x) returns function argument" );
		is( $edns->$_(),	 $changed, "edns->$_()	returns changed value" );
		$edns->$_(0);
	}

	foreach my $method (qw(class ttl size)) {
		exception( "deprecated $method method", sub { $edns->$method(512) } );
		noexception( "$method warning not repeated", sub { $edns->$method(512) } );
	}
}


for my $edns ( Net::DNS::Packet->new()->edns ) {
	is( scalar( $edns->options ), 0, 'EDNS option list initially empty' );

	my $non_existent = $edns->option(0);
	is( $non_existent, undef, 'non-existent option(0) returns undef' );

	ok( !$edns->_specified, 'state unmodified by existence probe' );

	$edns->option( 0 => '' );
	is( scalar( $edns->options ), 1, 'insert EDNS option' );

	$edns->option( 0 => undef );
	is( scalar( $edns->options ), 0, 'delete EDNS option' );

	ok( !$edns->_specified, 'state unmodified following delete' );

	my @transgression = ( {8 => {"FAMILY" => 99}}, {8 => {"BASE16" => '00990000'}}, {65001 => []} );
	foreach (@transgression) {
		my @test = _presentable($_);
		my ($option) = keys %$_;
		exception( "compose(@test)", sub { $edns->option(%$_); my @value = $edns->option($option) } );
	}
}


my $edns = Net::DNS::Packet->new()->edns;

foreach my $option ( keys %Net::DNS::Parameters::ednsoptionbyval ) {
	$edns->option( $option => {'BASE16' => '076578616d706c6500'} );
}


my @testcase = (
	["LLQ" => {"BASE16" => "000100000000000000000000000000000000"}],
	[["NSID" => {"OPTION-DATA" => "rawbytes"}], ["NSID" => {"IDENTIFIER" => "7261776279746573"}]],
	["4"		 => {"OPTION-DATA" => ""}],
	["DAU"		 => ( 8, 10, 13, 14, 15, 16 )],
	["DHU"		 => ( 1, 2,  4 )],
	["N3U"		 => 1],
	["CLIENT-SUBNET" => ( "FAMILY" => 1, "ADDRESS" => "192.0.2.1", "SOURCE-PREFIX" => 24 )],
	["CLIENT-SUBNET" => {"BASE16" => "0002380020010db8fd1342"}],
	["EXPIRE"	 => 604800],
	[["COOKIE" => ["7261776279746573", ""]], ["COOKIE" => "7261776279746573"]],
	["TCP-KEEPALIVE" => 200],
	[["PADDING" => {"OPTION-DATA" => ""}], ["PADDING" => 0], ["PADDING" => ""]],
	["PADDING"	  => {"OPTION-DATA" => "rawbytes"}],
	["PADDING"	  => 100],
	["CHAIN"	  => {"BASE16" => "076578616d706c6500"}],
	["KEY-TAG"	  => ( 29281, 30562, 31092, 25971 )],
	["EXTENDED-ERROR" => ( "INFO-CODE"    => 0, "EXTRA-TEXT" => '{"JSON":"EXAMPLE"}' )],
	["EXTENDED-ERROR" => ( "INFO-CODE"    => 0, "EXTRA-TEXT" => '{JSON: unparsable}' )],
	["EXTENDED-ERROR" => ( "INFO-CODE"    => 123 )],
	["REPORT-CHANNEL" => ( "AGENT-DOMAIN" => "example." )],
	[["ZONEVERSION" => ""], ["ZONEVERSION" => {"OPTION-DATA" => ""}], ["ZONEVERSION" => []]],
	["ZONEVERSION" => [2, 0, "12345678"]],
	);

foreach (@testcase) {
	my ( $canonical, @alternative ) = ref( $$_[0] ) eq 'ARRAY' ? @$_ : $_;
	my ( $option,	 @value )	= @$canonical;
	my @presentable = _presentable(@value);
	$edns->option( $option => @value );
	my $result = $edns->option($option);
	ok( defined($result), qq[compose( "$option" => @presentable )] );
	my $expect = defined($result) ? unpack( 'H*', $result ) : $result;
	my ($interpretation) = $edns->option($option);		# check option interpretation

	foreach ( [%$interpretation], @alternative ) {
		my ( $option, @value ) = @$_;
		my @presentable = _presentable(@value);
		$edns->option( $option, @value );
		my $value  = $edns->option($option);
		my $result = defined($value) ? unpack( 'H*', $value ) : $value;
		is( $result, $expect, qq[compose( "$option" => @presentable )] );
	}
}


is( Net::DNS::RR::OPT::_JSONify(undef),	  'null',      '_JSONify undef' );
is( Net::DNS::RR::OPT::_JSONify(1234567), '1234567',   '_JSONify integer' );
is( Net::DNS::RR::OPT::_JSONify('12345'), '12345',     '_JSONify string integer' );
is( Net::DNS::RR::OPT::_JSONify('1.234'), '1.234',     '_JSONify string non-integer' );
is( Net::DNS::RR::OPT::_JSONify('1e+20'), '1e+20',     '_JSONify string with exponent' );
is( Net::DNS::RR::OPT::_JSONify('abcde'), '"abcde"',   '_JSONify non-numeric string' );
is( Net::DNS::RR::OPT::_JSONify('\\092'), '"\\\\092"', '_JSONify escape character' );

my @json = Net::DNS::RR::OPT::_JSONify( {'BASE16' => '1234'} );
is( "@json", qq[{"BASE16": "1234"}], 'short BASE16 string' );


$edns->print;

my $options = $edns->options;
my $encoded = $edns->encode;
my $decoded = Net::DNS::RR->decode( \$encoded );
my @result  = $decoded->options;
is( scalar(@result), $options, "expected number of options ($options)" );


my $multiple = '. 0 CLASS0 TYPE41 \# 30 00130006010012345678 00130006020012345678 00130006030012345678';
for my $edns ( Net::DNS::RR->new($multiple) ) {
	my $encoded = $edns->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my @value   = $decoded->option('ZONEVERSION');
	is( scalar(@value), 3, 'EDNS multi-instance ZONEVERSION option' );
	$edns->print;
}

exit;


sub _presentable {
	my ( $value, @list ) = @_;
	if ( scalar @list ) {		## unstructured argument list
		my @token = _presentable( [$value, @list] );
		pop @token;
		shift @token;
		return @token;
	}

	if ( ref($value) eq 'HASH' ) {
		my @tags = keys %$value;
		my $tail = pop @tags;
		my @body = map {
			my ( $a, @z ) = _presentable( $$value{$_} );
			unshift @z, qq("$_" => $a);
			$z[-1] .= ',';
			@z;
		} @tags;
		my ( $a, @tail ) = _presentable( $$value{$tail} );
		unshift @tail, qq("$tail" => $a);
		return ( '{', @body, @tail, '}' );
	}

	if ( ref($value) eq 'ARRAY' ) {
		my @array = @$value;
		return qq([ ]) unless scalar @array;
		my @tail = _presentable( pop @array );
		my @body = map { my @x = _presentable($_); $x[-1] .= ','; @x } @array;
		return ( '[', @body, @tail, ']' );
	}

	my $string = "$value";		## stringify, then use isdual() as discriminant
	return $string if UTIL && Scalar::Util::isdual($value); # native integer
	for ($string) {
		unless ( utf8::is_utf8($value) ) {
			return $_ if /^-?\d{1,10}$/;		# integer (string representation)
			return $_ if /^-?\d+\.\d+$/;		# non-integer
			return $_ if /^-?\d(\.\d*)?e[+-]\d\d?$/;
		}
		s/^"(.*)"$/$1/;					# strip enclosing quotes
		s/"/\\"/g;					# escape interior quotes
	}
	return qq("$string");
}

