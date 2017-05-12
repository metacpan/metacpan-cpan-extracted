
use strict;
use warnings;

use Module::Build 0.38;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.38',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.38'
  },
  'dist_abstract' => 'Disqus.com API access',
  'dist_author' => [
    'Ben van Staveren <madcat@cpan.org>'
  ],
  'dist_name' => 'Net-Disqus',
  'dist_version' => '1.19',
  'license' => 'perl',
  'module_name' => 'Net::Disqus',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Class::Accessor' => '0',
    'JSON::PP' => '0',
    'LWP::UserAgent' => '0',
    'Try::Tiny' => '0',
    'URI' => '0',
    'URI::Escape' => '0',
    'overload' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
