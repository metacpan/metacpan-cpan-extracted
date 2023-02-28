# Note: this file has been initially created by Make::Build::Convert 0.20_01

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Safe::Caller',
   dist_author => 'Steven Schubiger <schubiger@cpan.org>',
   dist_version_from => 'lib/Safe/Caller.pm',
   requires => {
                 'boolean' => 0,
                 'Carp' => 0,
               },
   test_requires => {
                      'File::Spec' => 0,
                      'Test::More' => 0,
                    },
   license => 'perl',
   create_readme => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/stsc/Safe-Caller',
       },
   },
  );

$build->create_build_script;
