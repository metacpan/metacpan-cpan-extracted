use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Object::Sub',
    VERSION_FROM => 'lib/Object/Sub.pm',
    PREREQ_PM => {
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Object-Sub.git',
        bugtracker => 'https://github.com/hoytech/Object-Sub/issues',
      },
    },
);

WriteMakefile(%args);
