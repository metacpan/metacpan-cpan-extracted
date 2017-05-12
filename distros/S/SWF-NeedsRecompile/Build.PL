use 5.008;
use Module::Build;
Module::Build->new(
   module_name => 'SWF::NeedsRecompile',
   dist_author => 'Chris Dolan <cdolan@cpan.org>',
   license => 'perl',
   requires => {
      'perl' => 5.008,
      'File::Slurp' => 9999.09,
      'File::HomeDir' => '0.50',
      'Regexp::Common' => 2.120,
      'List::MoreUtils' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   add_to_cleanup => [ 'SWF-NeedsRecompile-*' ],
   create_readme => 1,
   create_makefile_pl => 'traditional',
)->create_build_script;
