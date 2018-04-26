use strict;
use warnings;

use ExtUtils::MakeMaker qw(6.48);

my %args = (
    NAME              => 'String::Compare::ConstantTime',
    AUTHOR            => ['Doug Hoyte <doug@hcsw.org>'],
    ABSTRACT_FROM     => 'lib/String/Compare/ConstantTime.pm',
    VERSION_FROM      => 'lib/String/Compare/ConstantTime.pm',
    PREREQ_PM         => {
                         },
    OBJECT            => 'ConstantTime.o',
    LICENSE           => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
        resources => {
            repository => 'git://github.com/hoytech/String-Compare-ConstantTime.git',
            bugtracker => 'https://github.com/hoytech/String-Compare-ConstantTime/issues',
        },
    },
    MIN_PERL_VERSION => 5.8.0,
);

WriteMakefile(%args);
