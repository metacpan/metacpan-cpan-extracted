use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Params::Validate::Micro',
    AUTHOR              => 'Hans Dieter Pearcey <hdp@cpan.org>',
    VERSION_FROM        => 'lib/Params/Validate/Micro.pm',
    ABSTRACT_FROM       => 'lib/Params/Validate/Micro.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Params::Validate' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Params-Validate-Micro-*' },
);
