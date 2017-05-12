use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl::ImportReport',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Perl/ImportReport.pm',
    ABSTRACT_FROM       => 'lib/Perl/ImportReport.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PPI'        => 0,
        'PPI::Util'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-ImportReport-*' },
);
