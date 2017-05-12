#!/usr/bin/perl

# Unit tests for the PITA::XML::Install class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 29;
use PITA::XML ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Core dies like expected' );
}





#####################################################################
# Create the support objects

my $md5sum  = 'MD5.0123456789abcdef0123456789abcdef';

my $request = PITA::XML::Request->new(
	scheme   => 'perl5',
	distname => 'Foo-Bar',
	file     => PITA::XML::File->new(
		filename => 'Foo-Bar-0.01.tar.gz',
		digest   => $md5sum,
		),
	);
isa_ok( $request, 'PITA::XML::Request' );

my $request5make = PITA::XML::Request->new(
	scheme   => 'perl5.make',
	distname => 'Foo-Bar',
	file     => PITA::XML::File->new(
		filename => 'Foo-Bar-0.01.tar.gz',
		digest   => $md5sum,
		),
	);
isa_ok( $request, 'PITA::XML::Request' );

my $request6 = PITA::XML::Request->new(
	scheme   => 'perl6',
	distname => 'Foo-Bar',
	file     => PITA::XML::File->new(
		filename => 'Foo-Bar-0.01.tar.gz',
		digest   => $md5sum,
		),
	);
isa_ok( $request, 'PITA::XML::Request' );

my $platform = PITA::XML::Platform->autodetect_perl5;
isa_ok( $platform, 'PITA::XML::Platform' );





#####################################################################
# Testing a sample of the functionality

# Create an empty install object
SCOPE: {
	my $install = PITA::XML::Install->new(
		request  => $request,
		platform => $platform,
		);
	isa_ok( $install,           'PITA::XML::Install'  );
	isa_ok( $install->request,  'PITA::XML::Request'  );
	isa_ok( $install->platform, 'PITA::XML::Platform' );
	is_deeply( [ $install->commands ], [], '->commands returns correct in list context' );
	is( scalar($install->commands), 0, '->commands returns correct in scalar context' );
	is_deeply( [ $install->tests ], [], '->tests returns correct in list context' );
	is( scalar($install->tests), 0, '->tests returns correct in scalar context' );
	is( $install->analysis, undef, '->analysis returns undef as expected' );
}





#####################################################################
# Test the scheme-compatibility checking

# Using a subscheme should be ok
SCOPE: {
	my $install = PITA::XML::Install->new(
		request  => $request5make,
		platform => $platform,
		);
	isa_ok( $install, 'PITA::XML::Install' );
	is( $install->request->scheme, 'perl5.make',
		'Scheme differ as expected' );
	is( $install->platform->scheme, 'perl5',
		'Scheme differ as expected' );
}

dies_like( sub { PITA::XML::Install->new(
	request  => $request6,
	platform => $platform,
	) },
	qr/Platform scheme does not match request scheme/,
	'->new(scheme mismatch) dies as expected' );





#####################################################################
# Test various other errors

# No request
dies_like( sub { PITA::XML::Install->new(
	request  => '',
	platform => $platform,
	) },
	qr/Invalid or missing request/,
	'->new(no request) dies as expected' );

# Bad (but tricksey) request
dies_like( sub { PITA::XML::Install->new(
	request  => 'PITA::XML::Request',
	platform => $platform,
	) },
	qr/Invalid or missing request/,
	'->new(bad request) dies as expected' );

# No platform
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => '',
	) },
	qr/Invalid or missing platform/,
	'->new(no platform) dies as expected' );

# Bad (but evil) platform
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => 'PITA::XML::Platform',
	) },
	qr/Invalid or missing platform/,
	'->new(no platform) dies as expected' );

# Invalid commands (several different ways)
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	commands => 1,
	) },
	qr/Invalid commands/,
	'->new(bad commands) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	commands => \"foo",
	) },
	qr/Invalid commands/,
	'->new(bad commands) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	commands => {},
	) },
	qr/Invalid commands/,
	'->new(bad commands) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	commands => [ 'PITA::XML::Command' ],
	) },
	qr/Invalid commands/,
	'->new(bad commands) dies as expected' );

# Invalid tests (several different ways)
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	tests    => 1,
	) },
	qr/Invalid tests/,
	'->new(bad tests) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	tests    => \"foo",
	) },
	qr/Invalid tests/,
	'->new(bad tests) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	tests    => {},
	) },
	qr/Invalid tests/,
	'->new(bad tests) dies as expected' );
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	tests    => [ 'PITA::XML::Test' ],
	) },
	qr/Invalid tests/,
	'->new(bad tests) dies as expected' );

# Bad analysis
dies_like( sub { PITA::XML::Install->new(
	request  => $request,
	platform => $platform,
	analysis => 'PITA::XML::Analysis',
	) },
	qr/Invalid analysis/,
	'->new(bad analysis) dies as expected' );
