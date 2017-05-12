use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Dopplr",
         version_from => 'lib/Net/Dopplr.pm',
         script_files => [ 'bin/dopplr' ],
         requires     => {
                          'Test::More'            => '0.62',
                          'LWP::UserAgent'        => 0,
                          'URI'                   => 0,
                          'JSON::Any'             => 0,
                          'Net::Google::AuthSub'  => '0.3',
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

