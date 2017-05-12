use strict;
use warnings;
use ExtUtils::MakeMaker;

# Check whether we're on one of the more popular
# non-POSIX systems before building

if ($^O =~ m/^(?:mswin32|dos|macos|os2|cygwin|v[mo]s|riscos|amigaos|beos|mpeix)$/) {
    die "NA: requires POSIX 1b platform\n";
}

if ($^O =~ m/openbsd/) {
    die "NA: OpenBSD does not seem to support the sched_yield system call";
}

WriteMakefile(
    NAME                => 'POSIX::SchedYield',
    AUTHOR              => 'Marc Beyer <japh@tirwhan.org>',
    VERSION_FROM        => 'lib/POSIX/SchedYield.pm',
    ABSTRACT_FROM       => 'lib/POSIX/SchedYield.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POSIX-SchedYield-*' },
);
