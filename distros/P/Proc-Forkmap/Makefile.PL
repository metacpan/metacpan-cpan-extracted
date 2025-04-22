use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

die "Perl 5.010 or higher required" if $] < 5.010;

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
        'File::Temp' => 0,
        'IO::Select' => 0,
        'POSIX'      => 0,
    },
    MIN_PERL_VERSION    => '5.010',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Proc-Forkmap-*' },
);
