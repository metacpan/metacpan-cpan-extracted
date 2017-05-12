use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Social",
         version_from => 'lib/Net/Social.pm',
         licence      => 'perl',
         requires     => {
                          'Test::More'            => '0.62',
						  'Module::Pluggable'     => '3.0',
                        },
         create_makefile_pl => 'traditional',
         script_files => [ 'bin/dumpfriends' ],
       );

$build->create_build_script;

