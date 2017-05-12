#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
		exit(0);
	}
	plan( tests => 9 );
}

use File::Spec::Functions ':ALL';
use Perl::Dist::Vanilla   ();
use URI::file             ();
use t::lib::Test          ();

sub cpan_uri {
	my $path  = rel2abs( catdir( 't', 'data', 'cpan' ) );
	ok( -d $path, 'Found CPAN directory' );
	ok( -d catdir( $path, 'authors', 'id' ), 'Found id subdirectory' );
	return URI::file->new($path . '\\');
}





#####################################################################
# Constructor Test

my $dist = Perl::Dist::Vanilla->new(
	t::lib::Test->paths(14),
	cpan     => cpan_uri(),
);
isa_ok( $dist, 'Perl::Dist::Vanilla' );
is( ref($dist->patch_include_path), 'ARRAY', '->patch_include_path ok' );
is( scalar(@{$dist->patch_include_path}), 2, 'Two include path entries' );
