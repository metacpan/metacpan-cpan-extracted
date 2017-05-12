use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Task::LMDB',
    VERSION_FROM => 'lib/Task/LMDB.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'Alien::LMDB' => 0,
    },
    PREREQ_PM => {
      'LMDB_File' => '0.10',
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Task-LMDB.git',
        bugtracker => 'https://github.com/hoytech/Task-LMDB/issues',
      },
    },
);

WriteMakefile(%args);
