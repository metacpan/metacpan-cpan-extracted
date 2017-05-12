BEGIN { require 5.006 } # our

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'MoneyWorks-pm',
    AUTHOR          => 'Father Chrysostomos <sprout at, um, cpan dot org>',
    VERSION_FROM    => 'lib/MoneyWorks.pm',
    ABSTRACT        => 'Perl interface to MoneyWorks accounting software',
    PL_FILES            => {},
    PREREQ_PM => {
     Carp                => 0,
     constant            => 1.03, # multiple at once
     constant'lexical    => 0,
     Exporter            => 5.57, # use Exporter 'import';
     File::Temp          => 0,
     IPC::Open3          => 0,
     Scalar::Util        => 0,
     strict              => 0,
     Symbol              => 0,
     warnings            => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'MoneyWorks-pm-*' },
);
