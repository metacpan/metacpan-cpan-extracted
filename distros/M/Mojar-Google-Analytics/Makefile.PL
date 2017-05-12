use 5.014001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar::Google::Analytics',
  VERSION_FROM => 'lib/Mojar/Google/Analytics.pm',
  ABSTRACT     => 'Fetch Google Analytics reporting data',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => 5.014001},
    resources => {
      homepage    => 'http://niczero.github.io/mojar',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojar-google-analytics',
      bugtracker  => 'http://github.com/niczero/mojar-google-analytics/issues'
    },
    no_index => {directory => [qw(data test)]}
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {
    Mojolicious => 7.15,
    Mojar => 2,
    'IO::Socket::SSL' => 1.75,
    'Crypt::OpenSSL::RSA' => 0.28
  },
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);
