# $Id: Build.PL,v 1.1 2008/07/02 16:20:12 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::ModestMaps',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/ModestMaps.pm',
			       license           => 'perl',
			       requires => {
                                            'LWP::UserAgent' => '0',
                                            'URI' => 0,
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
