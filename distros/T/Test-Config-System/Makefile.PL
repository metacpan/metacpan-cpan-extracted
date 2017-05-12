use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Config::System',
    AUTHOR              => 'Ian Kilgore <iank@cpan.org>',
    VERSION_FROM        => 'lib/Test/Config/System.pm',
    ABSTRACT_FROM       => 'lib/Test/Config/System.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Builder::Module' => 0,
        'File::Temp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Config-System-*' },
);
