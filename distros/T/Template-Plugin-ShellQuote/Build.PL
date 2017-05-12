use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name => "Template::Plugin::ShellQuote",
         license     => 'perl',
         requires    => {
                          'Test::More'    => 0,
                          'Template'      => 0,
                          'Template::Plugin::Filter' => 0,
                          'String::ShellQuote'  => 0,
                        },
         create_makefile_pl => 'passthrough',
       );

$build->create_build_script;

