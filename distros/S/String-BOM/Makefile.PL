use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::BOM',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/String/BOM.pm',
    ABSTRACT_FROM       => 'lib/String/BOM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'File::Slurp' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-BOM-*' },
);
