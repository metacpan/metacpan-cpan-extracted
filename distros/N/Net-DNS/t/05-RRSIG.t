#!/usr/bin/perl
# $Id: 05-RRSIG.t 1856 2021-12-02 14:36:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 71;


my $name = 'net-dns.org';
my $type = 'RRSIG';
my $code = 46;
my @attr = qw( typecovered algorithm labels orgttl sigexpiration siginception keytag signame signature );
my @data = (
	qw( NS	7  2  3600 20130914141655 20130815141655 60909	net-dns.org ),
	join '', qw(	IRlCjYNZCkddjoFw6UGxAga/EvxgENl+IESuyRH9vlrys
			yqne0gPpclC++raP3+yRA+gDIHrMkIwsLudqod4iuoA73
			Mw1NxETS6lm2eQTDNzLSY6dnJxZBqXypC3Of7bF3UmR/G
			NhcFIThuV/qFq+Gs+g0TJ6eyMF6ydYhjS31k= )
			);
my @also = qw( sig sigin sigex vrfyerrstr );

my $wire =
'0002070200000E1052346FD7520CE2D7EDED076E65742D646E73036F7267002119428D83590A475D8E8170E941B10206BF12FC6010D97E2044AEC911FDBE5AF2B32AA77B480FA5C942FBEADA3F7FB2440FA00C81EB324230B0BB9DAA87788AEA00EF7330D4DC444D2EA59B67904C33732D263A767271641A97CA90B739FEDB17752647F18D85C1484E1B95FEA16AF86B3E8344C9E9EC8C17AC9D6218D2DF59';


{
	my $typecode = unpack 'xn', Net::DNS::RR->new(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = Net::DNS::RR->new(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}


	my $empty   = Net::DNS::RR->new("$name $type");
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = uc unpack 'H*', $decoded->encode;
	my $hex2    = uc unpack 'H*', $encoded;
	my $hex3    = uc unpack 'H*', substr( $encoded, length $empty->encode );
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


{
	my @rdata	= @data;
	my $sig		= pop @rdata;
	my $lc		= Net::DNS::RR->new( lc(". $type @rdata ") . $sig );
	my $rr		= Net::DNS::RR->new( uc(". $type @rdata ") . $sig );
	my $hash	= {};
	my $predecessor = $rr->encode( 0,		    $hash );
	my $compressed	= $rr->encode( length $predecessor, $hash );
	ok( length $compressed == length $predecessor, 'encoded RDATA not compressible' );
	is( $rr->encode,    $lc->encode, 'encoded RDATA names downcased' );
	is( $rr->canonical, $lc->encode, 'canonical RDATA names downcased' );
}


{
	my $rr = Net::DNS::RR->new(". $type");
	foreach ( @attr, 'rdstring' ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr	  = Net::DNS::RR->new(". $type @data");
	my $class = ref($rr);

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );

	eval { $rr->algorithm('X'); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unknown mnemonic\t[$exception]" );

	is( $class->algorithm('RSASHA256'), 8,		 'class method algorithm("RSASHA256")' );
	is( $class->algorithm(8),	    'RSASHA256', 'class method algorithm(8)' );
	is( $class->algorithm(255),	    255,	 'class method algorithm(255)' );
}


{
	my $object   = Net::DNS::RR->new(". $type");
	my $class    = ref($object);
	my $scalar   = '';
	my %testcase = (		## methods callable with invalid arguments
		'_CreateSig'	 => [$object, $scalar, $object],
		'_CreateSigData' => [$object, $object],
		'_VerifySig'	 => [$object, $object, $object],
		'create'	 => [$class,  $scalar, $object],
		'verify'	 => [$object, $object, $object],
		);

	$object->{algorithm} = 0;				# induce exception

	foreach my $method ( sort keys %testcase ) {
		my $arglist = $testcase{$method};
		my ( $object, @arglist ) = @$arglist;
		eval { $object->$method(@arglist) };
		my ($exception) = split /\n/, "$@\n";
		ok( defined $exception, "$method method callable\t[$exception]" );
	}
}


{
	my %testcase = (		## test time conversion edge cases
		-1	   => '21060207062815',
		0x00000000 => '19700101000000',
		0x7fffffff => '20380119031407',
		0x80000000 => '20380119031408',
		0xf4d41f7f => '21000228235959',
		0xf4d41f80 => '21000301000000',
		0xffffffff => '21060207062815',
		);

	foreach my $time ( sort keys %testcase ) {
		my $string = $testcase{$time};
		my $result = Net::DNS::RR::RRSIG::_time2string($time);
		is( $result, $string, "_time2string($time)" );

		# Test indirectly: $timeval can be 64-bit or negative 32-bit integer
		my $timeval = Net::DNS::RR::RRSIG::_string2time($string);
		my $timestr = Net::DNS::RR::RRSIG::_time2string($timeval);
		is( $timestr, $string, "_string2time($string)" );
	}

	my $timenow = time();
	my $timeval = Net::DNS::RR::RRSIG::_string2time($timenow);
	is( $timeval, $timenow, "_string2time( time() )\t$timeval" );
}


{
	ok( Net::DNS::RR::RRSIG::_ordered( undef,	0 ),	      '_ordered( undef, 0 )' );
	ok( Net::DNS::RR::RRSIG::_ordered( 0,		1 ),	      '_ordered( 0, 1 )' );
	ok( Net::DNS::RR::RRSIG::_ordered( 0x7fffffff,	0x80000000 ), '_ordered( 0x7fffffff, 0x80000000 )' );
	ok( Net::DNS::RR::RRSIG::_ordered( 0xffffffff,	0 ),	      '_ordered( 0xffffffff, 0 )' );
	ok( Net::DNS::RR::RRSIG::_ordered( -2,		-1 ),	      '_ordered( -2, -1 )' );
	ok( Net::DNS::RR::RRSIG::_ordered( -1,		0 ),	      '_ordered( -1, 0 )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( undef,	undef ),      '!_ordered( undef, undef )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( 0,		undef ),      '!_ordered( 0, undef )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( 0x80000000, 0x7fffffff ), '!_ordered( 0x80000000, 0x7fffffff )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( 0,		0xffffffff ), '!_ordered( 0, 0xffffffff )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( -1,		-2 ),	      '!_ordered( -1, -2 )' );
	ok( !Net::DNS::RR::RRSIG::_ordered( 0,		-1 ),	      '!_ordered( 0, -1 )' );
}


{
	my $rr = Net::DNS::RR->new("$name $type @data");
	$rr->print;
}

exit;


