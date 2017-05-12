#!/usr/bin/perl

# Testing of the static path

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 16;
use Test::File::Cleaner   ();
use File::Spec::Functions ':ALL';
use Module::CGI::Install          ();
use URI::file             ();

my $cleaner = Test::File::Cleaner->new('t');





#####################################################################
# Configuration variables

my $static_dir = catdir( 't', 'data', 'static_dir' );
ok( -d $static_dir, 'The static_dir exists' );

my $static_uri = URI::file->new( rel2abs($static_dir) );
isa_ok( $static_uri, 'URI::file' );





#####################################################################
# Instantiation

SCOPE: {
	# Create the installation object
	my $cgi = Module::CGI::Install->new(
		interactive    => 0,
		install_cgi    => 0,
		install_static => 1,
		static_dir     => $static_dir,
		static_uri     => $static_uri->as_string,
	);
	isa_ok( $cgi, 'Module::CGI::Install' );

	# Check accessors
	is( $cgi->interactive,    '',           '->interactive ok'    );
	is( $cgi->install_cgi,    '',           '->install_cgi ok'    );
	is( $cgi->install_static, 1,            '->install_static ok' );
	is( $cgi->cgi_dir,        undef,        '->cgi_dir undef'    );
	is( $cgi->cgi_uri,        undef,        '->cgi_uri undef'     );
	is( $cgi->cgi_map,        undef,        '->cgi_map undef'     );
	is( $cgi->cgi_capture,    undef,        '->cgi_capture undef' );
	is( $cgi->static_dir,     $static_dir,  '->static_dir ok'     );
	is( $cgi->static_uri,     $static_uri,  '->statuc_uri ok'     );
	isa_ok( $cgi->static_map,  'URI::ToDisk' );

	# Validate the static path
	ok( ! -f $cgi->static_map->catfile('cgicapture.txt'), 'No file before test' );
	is( $cgi->validate_static_dir($cgi->static_map), 1, '->validate_static ok'  );
	ok( ! -f $cgi->static_map->catfile('cgicapture.txt'), 'No file after test'  );
}
