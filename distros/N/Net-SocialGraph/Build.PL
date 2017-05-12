use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Net::SocialGraph",
         license     => 'perl',
         requires    => {
                          'Test::More'            => '0.62',
                          'LWP::Simple'           => 0,
                          'URI'                   => 0,
                          'JSON::Any'             => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

