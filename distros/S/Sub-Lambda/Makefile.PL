use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Lambda',
    AUTHOR              => 'Anton Tayanovskyy <name.surname@gmail.com>',
    VERSION_FROM        => 'lib/Sub/Lambda.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
	'Memoize'           => 0,
	'Filter::Simple'    => 0,
	'Parse::RecDescent' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-Lambda-*' },
);
