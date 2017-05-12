# $Id: Build.PL,v 1.2 2007/09/02 18:55:24 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Flickr::Simile',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Flickr/Simile.pm',
			       license           => 'perl',
			       requires => {
                                            'Net::Flickr::API' => '>= 1.67',
                                            'IO::AtomicFile' => '0',
                                            'JSON::Any' => '1.08',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
