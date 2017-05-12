# Note: this file has been initially created by Make::Build::Convert 0.20_01

use 5.005;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Module::Build::Convert',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Module/Build/Convert.pm',
   requires => {
                 'Carp' => 0,
                 'Cwd' => 0,
                 'Data::Dumper' => 0,
                 'ExtUtils::MakeMaker' => 0,
                 'File::Basename' => 0,
                 'File::HomeDir' => 0,
                 'File::Slurp' => 0,
                 'File::Spec' => 0,
                 'Getopt::Long' => 0,
                 'IO::File' => 0,
                 'IO::Prompt' => 0,
                 'PPI' => 0,
                 'Text::Balanced' => 0,
               },
   build_requires => { 'Test::More' => 0 },
   recommends => {
                   'Test::Pod' => '1.14',
                   'Test::Pod::Coverage' => '1.04',
                 },
   script_files => [ 'scripts/make2build' ],
   license => 'perl',
   create_readme => 1,
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
