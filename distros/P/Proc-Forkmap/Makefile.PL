use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Proc::Forkmap',
    AUTHOR              => q{Andrew Shapiro <trski@cpan.org>},
    VERSION_FROM        => 'lib/Proc/Forkmap.pm',
    ABSTRACT_FROM       => 'lib/Proc/Forkmap.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Proc::Fork' => 0.71,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Proc-Forkmap-*' },
);
