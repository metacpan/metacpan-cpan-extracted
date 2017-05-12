# $Id: Build.PL,v 1.2 2005/12/11 19:29:33 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Delicious::Export',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Delicious/Export.pm',
			       license           => 'perl',
			       requires => {
                                            "XML::SAX"    => '>= 0.12',
                                            "MD5"        => 0,
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
