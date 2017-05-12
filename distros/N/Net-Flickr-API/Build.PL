# $Id: Build.PL,v 1.7 2009/08/02 17:16:12 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Flickr::API',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Flickr/API.pm',
			       license           => 'perl',
			       requires => {
				   'Config::Simple'  => '0',
				   'Flickr::API'     => '1.04',
				   'Flickr::Upload' => '1.32',
				   'Readonly'        => '0',
				   'Log::Dispatch'   => '2.10',
				   'XML::XPath'      => '1.13',
			       },
			       build_requires => {
				   'Test::Simple'              => '0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
