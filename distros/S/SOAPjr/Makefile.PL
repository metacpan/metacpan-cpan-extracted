use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SOAPjr',
    AUTHOR              => 'Rob Manson <robman@cpan.org>',
    VERSION_FROM        => 'lib/SOAPjr.pm',
    ABSTRACT_FROM       => 'lib/SOAPjr.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'JSON' => 0,
        'File::Basename' => 0,
        'File::Temp' => 0,
        'File::Copy' => 0,
        'URI::Escape' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SOAPjr-*' },
);
