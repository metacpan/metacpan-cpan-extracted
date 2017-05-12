
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Javascript PSGI apps via JSP',
  'dist_author' => [
    'Patrick Donelan <pat@patspam.com>'
  ],
  'dist_name' => 'Plack-App-JSP',
  'dist_version' => '0.101680',
  'license' => 'perl',
  'module_name' => 'Plack::App::JSP',
  'recommends' => {},
  'requires' => {
    'JSP' => '0',
    'Plack::Component' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
