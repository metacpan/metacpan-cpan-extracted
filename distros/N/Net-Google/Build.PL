# $Id: Build.PL,v 1.1 2005/03/26 20:49:03 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Google',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Google.pm',
			       license           => 'perl',
			       requires => {
				   'SOAP::Lite'     => '>= 0.55',
				   'LWP::Protocol'  => '>= 1.42',
				   'Carp'           => '>= 0',
			       },
			       build_requires => {
				   'Test::Simple'  => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
