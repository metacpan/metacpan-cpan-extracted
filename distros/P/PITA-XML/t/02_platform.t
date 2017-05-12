#!/usr/bin/perl

# Unit tests for the PITA::XML::Platform class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;
use Config    ();
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
# Testing a sample of the functionality

# Creating with bad params dies
dies( sub { PITA::XML::Platform->new },
	'->new(no params) dies' );

dies( sub { PITA::XML::Platform->new(
	path => 'foo',
	) },
	'->new(bin) dies as expected' );

# Again, but using a legal x_foo scheme
isa_ok( PITA::XML::Platform->new(
	scheme => 'x_foo',
	path   => 'foo',
	env    => { foo => 'bar' },
	config => { foo => 'bar' },
	), 'PITA::XML::Platform' );

# The easiest test to do is to get the current platform
my $perl5 = PITA::XML::Platform->autodetect_perl5;
isa_ok(    $perl5, 'PITA::XML::Platform' );
is(        $perl5->scheme, 'perl5',          '->scheme matches expected' );
is(        $perl5->path,   $^X,              '->bin matches expected'    );
is_deeply( $perl5->env,    \%ENV,            '->env matches expected'    );
is_deeply( $perl5->config, \%Config::Config, '->config matches expected' );





#####################################################################
# Check for specific errors

# A missing scheme
dies_like( sub { PITA::XML::Platform->new(
	scheme => '', # A close to legal as possible without being so
	path   => 'foo',
	env    => { foo => 'bar' },
	config => { foo => 'bar' },
	) },
	qr/Invalid or missing platform testing scheme/,
	'->new(missing scheme) dies like expected' );

# A bad scheme
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'foo', # Not in the core scheme set
	path   => 'foo',
	env    => { foo => 'bar' },
	config => { foo => 'bar' },
	) },
	qr/Invalid or missing platform testing scheme/,
	'->new(bad scheme) dies like expected' );

# A missing path
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => '',
	env    => { foo => 'bar' },
	config => { foo => 'bar' },
	) },
	qr/Invalid or missing scheme path/,
	'->new(missing path) dies like expected' );

# A missing env
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => 'foo',
	env    => '',
	config => { foo => 'bar' },
	) },
	qr/Invalid, missing, or empty environment/,
	'->new(missing env) dies like expected' );

# An empty env
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => 'foo',
	env    => { },
	config => { foo => 'bar' },
	) },
	qr/Invalid, missing, or empty environment/,
	'->new(empty env) dies like expected' );

# A missing config
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => 'foo',
	env    => { foo => 'bar' },
	config => '',
	) },
	qr/Invalid, missing, or empty config/,
	'->new(missing config) dies like expected' );

# An empty config
dies_like( sub { PITA::XML::Platform->new(
	scheme => 'perl5',
	path   => 'foo',
	env    => { foo => 'bar' },
	config => { },
	) },
	qr/Invalid, missing, or empty config/,
	'->new(empty config) dies like expected' );

exit(0);
