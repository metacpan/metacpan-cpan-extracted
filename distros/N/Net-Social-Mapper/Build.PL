use Module::Build;

my $build = Module::Build
  ->new( module_name   => "Net::Social::Mapper",
         dist_abstract => "Utilities for dealing with internet personas", 
         license       => 'perl',
         script_files  => [ ],
         requires      => {
                          'Email::Valid'               => 0,
                          'Email::Address'             => 0,
                          'Feed::Find'                 => 0,
                          'JSON::Any'                  => 0,
                          'LWP::UserAgent'             => 0,
                          'Test::More'                 => 0,
                          'URI'                        => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;


