#!/usr/bin/perl

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 32;
use Module::Inspector;

my $tarball = catfile( 't', 'dists', 'Config-Tiny-2.09.tar.gz' );
ok( -f $tarball, "Tarball file $tarball exists"      );
ok( -r $tarball, "Tarball file $tarball is readable" );





#####################################################################
# Create the handle

SCOPE: {
	my $mod = Module::Inspector->new( dist_file => $tarball );
	isa_ok( $mod, 'Module::Inspector' );
	is( $mod->dist_file, $tarball, '->dist_file ok' );
	is( $mod->dist_type, 'tgz', '->dist_type ok' );
	ok( -d $mod->dist_dir, '->dist_dir exists' );
	is( $mod->version_control, '', '->version_control is null' );
	my @docs = grep { ! /^t\/9/ } grep { ! /^inc\b/ } $mod->documents;
	is_deeply( \@docs, [qw{
		MANIFEST
		META.yml
		Makefile.PL
		lib/Config/Tiny.pm
		t/00_compile.t
		t/01_main.t
		}], '->documents ok' );

	# Check support for various document types
	my @types = qw{
		MANIFEST     Module::Manifest
		META.yml     YAML::Tiny
		Makefile.PL  PPI::Document::File
		};
	while ( @types ) {
		my $file = shift @types;
		my $type = shift @types;
		is( $mod->document_type($file), $type, "->document_type($type) ok" );
		isa_ok( $mod->document($file), $type );
		is( $mod->document_type($file), $type, "->document_type($type) ok" );
		isa_ok( $mod->document($file), $type );
	}

	# Analysis later
	is( $mod->dist_name, 'Config-Tiny', '->dist_name ok' );
	my $dist_version = $mod->dist_version;
	isa_ok( $dist_version, 'version' );
	is( "$dist_version",          '2.09',  '->dist_version ok' );
	is( $dist_version->stringify, '2.09',  '->dist_version ok' );
	is( $dist_version->numify,    '2.090', '->dist_version ok' );

	# Dependencies
	isa_ok( $mod->dist_requires,       'Module::Math::Depends' );
	isa_ok( $mod->dist_build_requires, 'Module::Math::Depends' );
	isa_ok( $mod->dist_depends,        'Module::Math::Depends' );

	# Strip build_requires to no deps and make sure it still
	# returns objects
	my $meta_yml = $mod->document('META.yml');
	isa_ok( $meta_yml, 'YAML::Tiny' );
	delete $meta_yml->[0]->{requires};
	delete $meta_yml->[0]->{build_requires};
	isa_ok( $mod->dist_requires,       'Module::Math::Depends' );
	isa_ok( $mod->dist_build_requires, 'Module::Math::Depends' );
	isa_ok( $mod->dist_depends,        'Module::Math::Depends' );
}
