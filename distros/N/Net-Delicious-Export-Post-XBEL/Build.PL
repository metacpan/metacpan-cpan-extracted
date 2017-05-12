# $Id: Build.PL,v 1.1 2005/12/11 19:08:21 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Delicious::Export::Post::XBEL',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Delicious/Export/Post/XBEL.pm',
			       license           => 'perl',
			       requires => {
                                            'Net::Delicious'         => '>= 0.93',
                                            'Net::Delicious::Export' => '>= 1.2',
                                            'String::Random'         => '0',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
