use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Social::Service::Jabber",
         version_from => 'lib/Net/Social/Service/Jabber.pm',
         requires     => {
                          'Test::More'            => '0.62',
						  'Net::Social'           => '0',
                          'Jabber::Connection'    => '0',
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

