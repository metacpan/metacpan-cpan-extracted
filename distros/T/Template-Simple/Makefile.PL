use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Simple',
    AUTHOR              => 'Uri Guttman <uri@sysarch.com>',
    VERSION_FROM        => 'lib/Template/Simple.pm',
    ABSTRACT_FROM       => 'lib/Template/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Simple-*' },
);
