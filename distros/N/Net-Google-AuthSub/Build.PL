use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Google::AuthSub",
         version_from => 'lib/Net/Google/AuthSub.pm',
         license      => 'perl',
         requires     => {
                          'Test::More'            => '0.62',
                          'LWP::UserAgent'        => 0,
                          'URI'                   => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

