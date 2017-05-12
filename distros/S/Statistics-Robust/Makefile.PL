use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Robust',
    AUTHOR              => 'Walter Szeliga <walter@geology.cwu.edu>',
    VERSION_FROM        => 'lib/Statistics/Robust.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Robust.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Test::Number::Delta' => 0,
        'Test::More'   => 0,
        'Math::CDF'    => 0.1,
	'Math::Round'  => 0,
	'Math::Random' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Robust-*' },
);
