use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME             => 'Mojo::IOLoop::Thread',
  VERSION_FROM     => 'lib/Mojo/IOLoop/Thread.pm',
  ABSTRACT         => 'Threaded Replacement for Mojo::IOLoop::Subprocess',
  AUTHOR           => 'Thomas Kratz <tomk@cpan.org>',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.016,
  META_MERGE       => {
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/tomk3003/mojo-ioloop-thread',
      bugtracker  => 'https://github.com/tomk3003/mojo-ioloop-thread/issues'
    },
    no_index => {directory => ['t']}
  },
  PREREQ_PM => { qw(
      Mojolicious 8.43
  ) },
  TEST_REQUIRES => { qw(
      Test::More 0.98
  ) },
  test => {TESTS => 't/*.t'}
);
