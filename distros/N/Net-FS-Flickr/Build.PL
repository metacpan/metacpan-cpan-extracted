use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Net::FS::Flickr",
         license     => 'perl',
         script_files => [ 'bin/flickrfs' ],
         requires    => {
                          'Test::More'                       => 0,
                          'File::Basename'                   => 0,
                          'Flickr::Upload'                   => 0,
                          'Acme::Steganography::Image::Png'  => '0.05',    
                          'LWP::Simple'                      => 0,
                          'File::Temp'                       => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

