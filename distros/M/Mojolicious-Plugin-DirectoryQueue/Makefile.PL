use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Mojolicious::Plugin::DirectoryQueue',
  AUTHOR => 'fu kai <iakuf@163.com>',
  EXE_FILES           => [],
  PL_FILES            => {},
  LICENSE => 'perl',
  DISTNAME  => 'Mojolicious-Plugin-DirectoryQueue',
  VERSION_FROM => 'lib/Mojolicious/Plugin/DirectoryQueue.pm',
  PREREQ_PM => {
    'Mojolicious' => '4.90',
    'Directory::Queue' => 0,
    'POSIX' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0.90,
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
    },
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'Mojolicious-Plugin-DirectoryQueue-*' },
  test => {
    TESTS => 't/*.t',
  },
);
