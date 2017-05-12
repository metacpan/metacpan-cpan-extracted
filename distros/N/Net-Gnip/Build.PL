use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Gnip",
         license      => 'perl',
         script_files => [ ],
         requires     => {
                          'LWP::UserAgent'             => 0,
                          'Test::More'                 => 0,
                          'DateTime'                   => 0,
                          'DateTime::Format::Strptime' => 0,
                          'DateTime::Format::ISO8601'  => 0,
                          'XML::LibXML'                => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

