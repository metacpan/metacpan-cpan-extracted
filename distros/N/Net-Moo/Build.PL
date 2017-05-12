# $Id: Build.PL,v 1.3 2008/06/19 15:15:34 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Moo',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Net/Moo.pm',
			       license           => 'perl',
			       requires => {
                                            'perl'               => '>= 5.8.0',                                            
                                            'Config::Simple'  => '0',
                                            'Log::Dispatch'   => '>= 2.10',
                                            'XML::XPath'      => '>= 1.13',
                                            'IO::String' => '0',
                                            'XML::Writer' => '0',
                                            'LWP::UserAgent' => '0',
			       },
			       build_requires => {
                                                  'Test::Simple' => '>= 0.47',
                                                  'Digest::MD5' => '0',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
