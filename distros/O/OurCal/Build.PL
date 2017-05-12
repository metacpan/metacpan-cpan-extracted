use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name  => "OurCal",
         license      => 'perl',
         version_from => 'lib/OurCal.pm',
         script       => [ ],
         requires     => {
                            'CGI'                      => 0, 
                            'CGI::Carp'                => 0,
                            'Carp'                     => 0, 
                            'Config::INI::Reader'      => 0, 
                            'DBI'                      => 0, 
                            'Data::ICal::DateTime'     => 0, 
                            'Data::ICal::Entry::Event' => 0, 
                            'DateTime'                 => 0, 
                            'DateTime::Span'           => 0, 
                            'Digest::MD5'              => 0, 
                            'File::Path'               => 0, 
                            'File::Spec'               => 0, 
                            'HTTP::Date'               => 0, 
                            'LWP::Simple'              => 0, 
                            'Lingua::EN::Numbers::Ordinate'  => 0, 
                            'Module::Pluggable'        => 0, 
                            'Storable'                 => 0, 
                            'Template'                 => 0, 
                            'Test::More'               => '0.62',
                            'Text::Chump'              => 0, 
                            'UNIVERSAL::require'       => 0,
                            'URI::Find::Simple'        => 0, 
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

