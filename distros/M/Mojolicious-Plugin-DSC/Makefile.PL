use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Mojolicious::Plugin::DSC',
  VERSION_FROM  => 'lib/Mojolicious/Plugin/DSC.pm',
  ABSTRACT_FROM => 'lib/Mojolicious/Plugin/DSC.pm',
  MIN_PERL_VERSION => '5.10.1',
  AUTHOR        => q{Красимир Беров <berov@cpan.org>},
  LICENSE       => 'artistic_2',
  PREREQ_PM     => {'Mojolicious' => '6.0', 'DBIx::Simple::Class' => '1.009'},
  META_MERGE    => {
    requires  => {perl => '5.010001'},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'https://github.com/kberov/Mojolicious--Plugin--DSC',
      bugtracker => 'https://github.com/kberov/Mojolicious--Plugin--DSC/issues'
    },
    no_index => {directory => ['t']}
  },
  test => {TESTS => 't/*.t'},
  dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean => {FILES    => 'Mojolicious-Plugin-DSC-*'},
);
