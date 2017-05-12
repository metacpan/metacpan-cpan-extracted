use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Net::FS::Gmail",
         license     => 'perl',
         script_files => [ 'bin/gmailfs' ],
         requires    => {
                          'Test::More'            => 0,
                          'File::Basename'        => 0,
                          'Mail::Webmail::Gmail'  => '1.05.1',
                          'Time::ParseDate'       => 0,
                          'URI::Escape'           => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

