use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Social::Service::Twitter",
         version_from => 'lib/Net/Social/Service/Vox.pm',
         requires     => {
                          'Test::More'            => '0.62',
						  'Net::Social'           => '0',
                          'Net::Twitter'          => '1.06',
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

