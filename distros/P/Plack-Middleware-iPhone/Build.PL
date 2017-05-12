
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'HTML::Tidy' => '0',
    'HTTP::Request::Common' => '0',
    'Module::Build' => '0.3601',
    'Plack::Builder' => '0',
    'Plack::Test' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Make your html more iPhone friendly',
  'dist_author' => [
    'Patrick Donelan <pat@patspam.com>'
  ],
  'dist_name' => 'Plack-Middleware-iPhone',
  'dist_version' => '1.102060',
  'license' => 'perl',
  'module_name' => 'Plack::Middleware::iPhone',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Digest::MD5' => '0',
    'File::Slurp' => '0',
    'HTML::DOM' => '0',
    'Plack::Middleware' => '0',
    'Plack::Util::Accessor' => '0',
    'UNIVERSAL::require' => '0',
    'parent' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
