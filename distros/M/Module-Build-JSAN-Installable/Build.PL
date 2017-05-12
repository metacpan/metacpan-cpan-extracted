
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Capture::Tiny' => '0.06',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Build JavaScript distributions for JSAN, which can be installed locally',
  'dist_author' => [
    'Nickolay Platonov <nplatonov@cpan.org>'
  ],
  'dist_name' => 'Module-Build-JSAN-Installable',
  'dist_version' => '0.13',
  'license' => 'perl',
  'module_name' => 'Module::Build::JSAN::Installable',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'JSON' => '2.00',
    'Module::Build' => '0.35',
    'Module::Build::JSAN' => '0.05',
    'Path::Class' => '0.16',
    'Text::Markdown' => '1.0.26',
    'Text::MultiMarkdown' => '1.0.29'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
