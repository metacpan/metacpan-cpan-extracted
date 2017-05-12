use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POSIX::Open3',
    AUTHOR              => q{Alberto Simoes <ambs@cpan.org>},
    VERSION_FROM        => 'lib/POSIX/Open3.pm',
    ABSTRACT_FROM       => 'lib/POSIX/Open3.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'POSIX'      => 0,
                  'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POSIX-Open3-*' },
);
