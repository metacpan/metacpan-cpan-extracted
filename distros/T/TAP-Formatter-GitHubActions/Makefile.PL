use 5.016;

use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME => 'TAP::Formatter::GitHubActions',
  VERSION_FROM => 'lib/TAP/Formatter/GitHubActions.pm',
  PREREQ_PM => {
    'TAP::Harness' => 3.12,
  },
  TEST_REQUIRES => {
    'Test::More' => '0',
  },
  ABSTRACT_FROM => 'lib/TAP/Formatter/GitHubActions.pm',
  MIN_PERL_VERSION => '5.016000',
  META_MERGE => {
    dynamic_config => 0,
    "meta-spec" => {version => 2},
    prereqs => {
      runtime => {
        suggests => {
          'Test2::Formatter::YAMLEnhancedTAP' => '0.0.3',
        }
      }
    },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/josegomezr/TAP-Formatter-GitHubActions.git',
        web => 'https://github.com/josegomezr/TAP-Formatter-GitHubActions',
      },
      bugtracker => {
        web => 'https://github.com/josegomezr/TAP-Formatter-GitHubActions/issues',
      },
    },
  },
  AUTHOR => 'Jose D. Gomez R. <1josegomezr@gmail.com>',
  LICENSE => 'perl',
);
