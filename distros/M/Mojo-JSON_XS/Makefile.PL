use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::JSON_XS',
  VERSION_FROM => 'lib/Mojo/JSON_XS.pm',
  ABSTRACT     => 'Use XS JSON with Mojolicious',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => 5.010_001},
    resources => {
      homepage    => 'http://niczero.github.io/mojo-jsonxs',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojo-jsonxs',
      bugtracker  => 'http://github.com/niczero/mojo-jsonxs/issues'
    },
    no_index => {directory => [qw(data test)]}
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {
    Mojolicious => 5.66,
    'Cpanel::JSON::XS' => 3.0109
  },
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);
