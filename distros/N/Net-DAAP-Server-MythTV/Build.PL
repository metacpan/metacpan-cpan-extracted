# vi: ts=4 sw=4

use strict;
use warnings;

use Module::Build;

Module::Build->new(module_name => 'Net::DAAP::Server::MythTV',
				   license => 'perl',
				   requires => {'perl' => 5,
								'DBI' => 0,
								'POE::Component::Server::HTTP' => 0,
								'Net::DAAP::DMAP' => 0},
				   create_makefile_pl => 'traditional',
				   create_readme => 1,
				   sign => 1)->create_build_script;
