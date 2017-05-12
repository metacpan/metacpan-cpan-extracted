use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Social::Service::Vox",
         version_from => 'lib/Net/Social/Service/Vox.pm',
         requires     => {
                          'Test::More'            => '0.62',
						  'Net::Social'           => '0',
                          'LWP::Simple'           => '0',
                          'IO::Scalar'            => '0',
                          'XML::XPath'            => '0',
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

