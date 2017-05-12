use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PDF::Report',
    AUTHOR              => 'Andy Orr <aorr_at_cpan_dot_org>',
    VERSION_FROM        => 'lib/PDF/Report.pm',
    ABSTRACT_FROM       => 'lib/PDF/Report.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'PDF::API2' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDF-Report-*' },
     META_MERGE => {
     resources => {
       repository => 'https://github.com/hashbangperl/perl-pdf-report',
    },
   },
   ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),

);
