#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;
use File::Spec::Functions;


my %requires = (
	perl => '5.6.1',

	'SOAP::Lite'    => 0,
	'LWP'           => 0,
	'Log::Log4perl' => 0,
	'Digest::MD5'   => 0,
	'File::Slurp'   => 0,
	'File::Spec'    => 0,
	'File::Path'    => 0,
	'XML::LibXML'   => 0,
);

my %configure_requires = (
	'File::Spec::Functions' => 0,
);

my $build = Module::Build->new(
	module_name       => 'SOAP::Transport::HTTP::Log4perl',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('lib', 'SOAP', 'Transport', 'HTTP', 'Log4perl.pm'),

	# Dependencies
	requires => \%requires,

	configure_requires => \%configure_requires,

	build_requires => {
		%configure_requires,
	},

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/potyl/pexeso',
			bugtracker => 'http://github.com/potyl/pexeso/issues',
			repository => 'http://github.com/potyl/pexeso',
		},
	},
);


$build->create_build_script();
