#!/usr/bin/perl

# Compile-testing for PITA::Scheme::Perl::Discovery

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use File::Spec::Functions ':ALL';
use PITA::Scheme::Perl::Discovery;

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Code dies like expected' );
}

use Config;

my $request = rel2abs( catfile( 't', 'prepare', 'injector', 'request.pita' ) );
ok( -f $request, 'Found request.pita' );
ok( -r $request, 'Confirm request.pita read permissions' );
ok( ! -x $request, 'Confirm request.pita no-execute permissions' );





#####################################################################
# Find the executable for the current Perl

# Find the path to the current Perl (implementation taken from perlport)
my $thisperl = $^X;
if ( $^O ne 'VMS' and $thisperl !~ m/$Config{_exe}$/i ) {
	$thisperl .= $Config{_exe};
}





#####################################################################
# Main Tests

my $discover = PITA::Scheme::Perl::Discovery->new( path => $thisperl );
isa_ok( $discover, 'PITA::Scheme::Perl::Discovery' );

# Check for various errors
dies_like(
	sub { PITA::Scheme::Perl::Discovery->new },
	qr/Did not provide a path to perl/,
);

my $path = 'foo';
dies_like(
	sub { PITA::Scheme::Perl::Discovery->new( path => $path ); },
	qr/The path foo is not absolute/,
);

$path = rel2abs( $path );
dies_like(
	sub { PITA::Scheme::Perl::Discovery->new( path => $path ); },
	qr/The path .*foo does not exist/,
);

$path = rel2abs( catfile('t', 'prepare') );
dies_like(
	sub { PITA::Scheme::Perl::Discovery->new( path => $path ); },
	qr/The path .*prepare does not exist/,
);

dies_like(
	sub { PITA::Scheme::Perl::Discovery->new( path => $request ); },
	qr/The path .+ is not executable/,
);





#####################################################################
# Live Testing

ok( $discover->delegate(
	'-I' . catdir('blib', 'lib'),
	'-I' . catdir('blib', 'arch'),
	'-I' . 'lib' ),
	'->delegate returns true',
);
isa_ok( $discover->platform, 'PITA::XML::Platform' );
