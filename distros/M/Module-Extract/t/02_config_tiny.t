
#!/usr/bin/perl -w

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Module::Extract;

my $tarball = catfile( 't', 'dists', 'Config-Tiny-2.09.tar.gz' );
ok( -f $tarball, "Tarball file $tarball exists"      );
ok( -r $tarball, "Tarball file $tarball is readable" );





#####################################################################
# Create the handle

SCOPE: {
	my $mod = Module::Extract->new( dist_file => $tarball );
	isa_ok( $mod, 'Module::Extract' );
	is( $mod->dist_file, $tarball, '->dist_file ok' );
	is( $mod->dist_type, 'tgz', '->dist_type ok' );
	ok( -d $mod->dist_dir, '->dist_dir exists' );
	ok( -f $mod->file_path('MANIFEST'), '->file_path ok' );
	ok( -d $mod->dir_path('t'),   '->dir_path ok' );
}
