use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Net::Posterous",
         license      => 'perl',
         script_files => [ ],
         requires     => {
                          'Class::Accessor'            => "0.34",
                          'DateTime'                   => "0",
                          'DateTime::Format::Strptime' => "0",
                          'LWP::UserAgent'             => "0",
                          'Test::More'                 => "0.06",
                          'XML::Simple'                => "0",
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;
