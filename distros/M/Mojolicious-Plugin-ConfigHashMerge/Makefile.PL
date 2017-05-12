use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ConfigHashMerge',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ConfigHashMerge.pm',
  AUTHOR       => 'Dotan Dimet <dotan@corky.net>',
  PREREQ_PM    => {'Mojolicious' => '4.85', 'Hash::Merge::Simple' => '0.051' },
  LICENSE      => 'artistic_2',
  ABSTRACT     => 'Perlish Configuration for Mojolicious, with merging of deeply-nested defaults',
  META_MERGE   => {
    requires   => {perl => '5.010001'},
    resources  => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/dotandimet/Mojolicious-Plugin-ConfigHashMerge',
      bugtracker  => 'http://github.com/dotandimet/Mojolicious-Plugin-ConfigHashMerge/issues',
      },
    no_index     => {directory => ['t']},
  },
  test         => {TESTS => 't/*.t'}
);
