use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Module::PluginFinder',
   dist_version_from => 'lib/Module/PluginFinder.pm',
   requires => {
                 'Module::Pluggable::Object' => 0,
               },
   build_requires => {
                 'File::Spec' => 0,
                 'Test::More' => 0,
                 'Test::Exception' => 0,
                 'Test::Warn' => 0,
               },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
  );
  
$build->create_build_script;
