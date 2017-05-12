#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PDF::API2::Tweaks',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/PDF/API2/Tweaks.pm',
    ABSTRACT_FROM       => 'lib/PDF/API2/Tweaks.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'PDF::API2' => 2.019,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDF-API2-Tweaks-*' },
);
