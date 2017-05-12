#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use File::Spec::Functions ':ALL';
use Perl::Dist::Asset::Distribution;





#####################################################################
# Main Tests

# Traditional distribution
SCOPE: {
	my $object = Perl::Dist::Asset::Distribution->new(
		name => 'RKOBES/PPM-0.01_01.tar.gz',
	);
	isa_ok( $object, 'Perl::Dist::Asset::Distribution' );
	is( $object->name, 'RKOBES/PPM-0.01_01.tar.gz', '->name ok' );
	is( $object->url,  'RKOBES/PPM-0.01_01.tar.gz', '->url ok' );
	is(
		$object->abs_uri(URI->new('http://cpan.org/')),
		'http://cpan.org/authors/id/R/RK/RKOBES/PPM-0.01_01.tar.gz',
		'->abs_uri ok',
	);
}

# Absolute distribution
SCOPE: {
	my $object = Perl::Dist::Asset::Distribution->new(
		name => 'RKOBES/PPM-0.01_01.tar.gz',
		url  => 'http://strawberryperl.com/package/PPM-0.01_01.tar.gz',
	);
	isa_ok( $object, 'Perl::Dist::Asset::Distribution' );
	is( $object->name, 'RKOBES/PPM-0.01_01.tar.gz', '->name ok' );
	is( $object->url,  'http://strawberryperl.com/package/PPM-0.01_01.tar.gz', '->url ok' );
	is( $object->abs_uri(URI->new('http://cpan.org/')), $object->url, '->abs_uri ok' );
}
