#!/usr/bin/perl

# Testing of installing files

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 24;
use Test::File::Cleaner   ();
use File::Spec::Functions ':ALL';
use Module::CGI::Install          ();
use URI::file             ();

my $cleaner = Test::File::Cleaner->new('t');





#####################################################################
# Configuration variables

my $static_dir = catdir( 't', 'data', 'static_dir' );
ok( -d $static_dir, 'The static_dir exists' );
my $static_uri = URI::file->new( rel2abs( $static_dir ) );
isa_ok( $static_uri, 'URI::file' );
my $cgi_dir = catdir( 't', 'data', 'cgi_dir' );
ok( -d $cgi_dir, 'The cgi_dir exists' );
my $cgi_mock = catdir( 't', 'data', 'cgi_mock' );
ok( -d $cgi_mock, 'The cgi_mock exists' );
my $cgi_uri = URI::file->new( rel2abs( $cgi_mock ) );
isa_ok( $cgi_uri, 'URI::file' );





#####################################################################
# Instantiation

# Create the installation object
my $cgi = Module::CGI::Install->new(
	interactive    => 0,
	install_static => 1,
	static_dir     => $static_dir,
	static_uri     => $static_uri->as_string,
	install_cgi    => 1,
	cgi_dir        => $cgi_dir,
	cgi_uri        => $cgi_uri->as_string,
);
isa_ok( $cgi, 'Module::CGI::Install' );

SCOPE: {
	my $cleaner = Test::File::Cleaner->new('t');

	# Specify what to install
	ok( $cgi->add_script('CGI::Capture', 'cgicapture'),     '->add_script(CGI::Capture, cgicapture) ok' );
	ok( $cgi->add_class('CGI::Capture'), '->add_class() ok'         );

	# Check accessors
	is( $cgi->interactive,    '',           '->interactive ok'    );
	is( $cgi->install_cgi,    1,            '->install_cgi ok'    );
	is( $cgi->install_static, 1,            '->install_static ok' );
	is( $cgi->cgi_dir,        $cgi_dir,     '->cgi_dir ok'        );
	is( $cgi->cgi_uri,        $cgi_uri,     '->statuc_uri ok'     );
	isa_ok( $cgi->cgi_map, 'URI::ToDisk' );
	is( $cgi->cgi_map->path,  $cgi_dir,     '->cgi_dir ok'        );
	is( $cgi->cgi_map->uri,   $cgi_uri,     '->cgi_uri ok'        );
	is( $cgi->static_dir,     $static_dir,  '->static_dir undef'  );
	is( $cgi->static_uri,     $static_uri,  '->static_uri undef'  );
	isa_ok( $cgi->static_map, 'URI::ToDisk' );

	# Run the prepare method, which should consider everything ok
	ok( $cgi->prepare, '->prepare ok' );
	isa_ok( $cgi->cgi_capture, 'CGI::Capture' );
}

SCOPE: {
	my $cleaner = Test::File::Cleaner->new('t');

	# Execute the installer to install the files
	ok( $cgi->run, '->run ok' );
	my $installed_bin = $cgi->cgi_map->catfile('cgicapture')->path;
	ok( -f $installed_bin, "Installed file created '$installed_bin'" );
	my $installed_class = $cgi->cgi_map->catfile('lib', 'CGI', 'Capture.pm')->path;
	ok( -f $installed_class, "Installed file created '$installed_class'" );

}
