
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Spec::Functions' => '0',
    'File::Temp' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Test' => '0',
    'Test::More' => '0.88',
    'Time::Local' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Save responses to disk to mirror a site',
  'dist_author' => [
    'Randy Stauner <rwstauner@cpan.org>'
  ],
  'dist_name' => 'Plack-Middleware-Mirror',
  'dist_version' => '0.401',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::Mirror',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'File::Path' => '0',
    'File::Spec' => '0',
    'HTTP::Date' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util' => '0',
    'Plack::Util::Accessor' => '0',
    'parent' => '0',
    'perl' => '5.006'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
