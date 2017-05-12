#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More             0.86 tests => 61;
use LWP::Online                 ':skip_all';
use File::Spec::Functions       ':ALL';
use Perl::Dist::Util::Toolchain ();
use Probe::Perl                 ();

my $perl = Probe::Perl->find_perl_interpreter;
@Perl::Dist::Util::Toolchain::DELEGATE = (
	$perl, '-Mblib',
);





#####################################################################
# Create and execute a resolver

sub check_simple_object {
	my $toolchain = shift;
	is( $toolchain->errstr, undef, '->errstr returns false' );
	is( $toolchain->perl_version, '5.008008', '->perl_version ok' );
	my @modules = $toolchain->modules;
	is_deeply( \@modules, [ 'File::Spec' ], 'List ->modules ok' );
	is( scalar($toolchain->modules), 1, 'Scalar ->modules ok' );
	my @dists = $toolchain->dists;
	is( scalar($toolchain->dists), 1, 'Scalar ->dists ok' );
	is( scalar(@dists), 1, 'Got one distribution' );
	like( $dists[0], qr/PathTools/, 'Got expected dist filename' );
}

# Test the simplest run-mode
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008008',
		cpan         => 'http://cpan.strawberryperl.com/',
		modules      => [ 'File::Spec' ],
	] );
	my $p = $toolchain->prepare;
	unless ( $p ) {
		my $message = '';
		if ( $@ =~ /Permission denied/ ) {
			$message = "No permissions to test, skipping";
		} elsif ( $@ =~ /Transfer truncated/ ) {
			$message = "Bad internet connection, skipping";
		}
		if ( $message ) {
			foreach ( 2 .. 61 ) {
				ok( 1, 'No permissions to test, skipping' );
			}
			exit(0);
		}
	}
	ok( $p, '->prepare ok' );
	ok( $toolchain->run,     '->run ok'     );
	check_simple_object( $toolchain );
}

# Test the force option
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008008',
		cpan         => 'http://cpan.strawberryperl.com/',
		modules      => [ 'File::Spec' ],
		force        => {
			'File::Spec' => 'PathTools-forced',
		},
	] );
	ok( $toolchain->prepare, '->prepare ok' );
	ok( $toolchain->run,     '->run ok'     );
	check_simple_object( $toolchain );
	is( ($toolchain->dists)[0], 'PathTools-forced', 'Force option works' );
}

# Test via a delegation
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008008',
		cpan         => 'http://cpan.strawberryperl.com/',
		modules      => [ 'File::Spec' ],
	] );
	isa_ok( $toolchain, 'Perl::Dist::Util::Toolchain' );
	ok( $toolchain->delegate, '->prepare ok' );
	check_simple_object( $toolchain );
}

# Test a full set for Perl 5.008008
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008008',
		cpan         => 'http://cpan.strawberryperl.com/',
	] );
	is( $toolchain->perl_version, '5.008008', '->perl_version ok' );
	ok( $toolchain->prepare, '->prepare ok' );
	ok( $toolchain->run,     '->run ok'     );
	is( $toolchain->errstr, undef, '->errstr is undef' );
	my @dists = $toolchain->dists;
	ok( scalar(@dists) > 5, 'Got at least 5 distributions' );
}

# Test a full set for Perl 5.008009
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008009',
		cpan         => 'http://cpan.strawberryperl.com/',
	] );
	is( $toolchain->perl_version, '5.008009', '->perl_version ok' );
	ok( $toolchain->prepare, '->prepare ok' );
	ok( $toolchain->run,     '->run ok'     );
	is( $toolchain->errstr, undef, '->errstr is undef' );
	my @dists = $toolchain->dists;
	ok( scalar(@dists) > 5, 'Got at least 5 distributions' );
}

# Test a full set for Perl 5.010000
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.010000',
		cpan         => 'http://cpan.strawberryperl.com/',
	] );
	is( $toolchain->perl_version, '5.010000', '->perl_version ok' );
	ok( $toolchain->prepare, '->prepare ok' );
	ok( $toolchain->run,     '->run ok'     );
	is( $toolchain->errstr, undef, '->errstr is undef' );
	my @dists = $toolchain->dists;
	ok( scalar(@dists) > 5, 'Got at least 5 distributions' );
}

# Test a full set for Perl 5.008008 via delegation
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.008008',
		cpan         => 'http://cpan.strawberryperl.com/',
	] );
	is( $toolchain->perl_version, '5.008008', '->perl_version ok' );
	ok( $toolchain->prepare,  '->prepare ok' );
	ok( $toolchain->delegate, '->run ok'     );
	is( $toolchain->errstr, undef, '->errstr is undef' );
	my @dists = $toolchain->dists;
	ok( scalar(@dists) > 5, 'Got at least 5 distributions' );
}

# Test a full set for Perl 5.010000 via delegation
SCOPE: {
	my $toolchain = new_ok( 'Perl::Dist::Util::Toolchain', [
		perl_version => '5.010000',
		cpan         => 'http://cpan.strawberryperl.com/',
	] );
	is( $toolchain->perl_version, '5.010000', '->perl_version ok' );
	ok( $toolchain->prepare,  '->prepare ok' );
	ok( $toolchain->delegate, '->run ok'     );
	is( $toolchain->errstr, undef, '->errstr is undef' );
	my @dists = $toolchain->dists;
	ok( scalar(@dists) > 5, 'Got at least 5 distributions' );
}
