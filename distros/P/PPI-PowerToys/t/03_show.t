#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::Spec::Functions ':ALL';
use Probe::Perl ();
use IPC::Run3   ();

my $perl = Probe::Perl->find_perl_interpreter;
ok( -f $perl, 'Found perl interpreter' );

# Run show against ourself
my $script = catfile('script', 'ppi_version');
my $stdout = '';
my $result = IPC::Run3::run3( [
	$perl,
	'-Mblib',
	$script,
	'show',
], \undef, \$stdout, \undef );
is( $result, 1, 'run3 returns true' );

foreach ( qw{
	Makefile.PL... no version
	lib/PPI/PowerToys.pm... 0.14
	script/ppi_version... 0.14
	t/01_compile.t... no version
} ) {
	my $string = quotemeta $_;
	like(
		$stdout,
		qr/$string/,
		"Found version for $_",
	);
}
