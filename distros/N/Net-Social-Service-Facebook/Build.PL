use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Social::Service::Facebook",
         version_from => 'lib/Net/Social/Service/Facebook.pm',
         requires     => {
                          'Test::More'            => '0.62',
						  'Net::Social'           => '0',
                          'WWW::Facebook::API'    => '0.4.4',
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

