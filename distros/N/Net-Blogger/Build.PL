# $Id: Build.PL 1433 2006-09-25 23:23:35Z claco $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Blogger',
			       dist_author     => 'Christopher H. Laco <claco@chrislaco.com>',
			       dist_abstract_from => 'lib/Net/Blogger.pm',
			       dist_version_from => 'lib/Net/Blogger.pm',
			       license           => 'perl',
			       requires => {
				   'SOAP::Lite'    => '>= 0.55',
				   'CGI'           => '>= 0',
				   'Carp'          => '>= 0',
				   'Error'         => '>= 0',
				   'URI'           => '>= 0',
				   'Digest::MD5'   => '>= 0',
				   'HTTP::Cookies' => '>= 0',
			       },
			       build_requires => {
				   'Term::ReadKey' => '>= 0',
				   'Test::Simple'  => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'traditional');

$build->create_build_script();
