use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Google::Calendar::Server",
         license      => 'perl',
         script_files => [ ],
         requires     => {
#                          'Apache::Constants'    => 0,
#                          'Apache2::RequestRec'  => 0,
                          'Data::ICal::DateTime' => 0,
                          'LWP::UserAgent'       => 0,
                          'XML::Atom'            => 0,
                          'Test::More'           => 0,
                          'DateTime'             => 0,
                          'URI'                  => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

