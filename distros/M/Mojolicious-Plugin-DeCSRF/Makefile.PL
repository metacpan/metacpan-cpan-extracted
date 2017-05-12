use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::DeCSRF',
  ABSTRACT     => 'Defend from CSRF attacks',
  LICENSE      => 'artistic_2',
  VERSION_FROM => 'lib/Mojolicious/Plugin/DeCSRF.pm',
  AUTHOR       => 'Ilya Tokarev <sysadm@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '3.84'},
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0'
    },
    no_index => {directory => ['t']}
  },
  test         => {TESTS => 't/*.t'}
);
