use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Unique',
    AUTHOR              => q{Christian Werner <saltbreez@cpan.org>},
    VERSION_FROM        => 'lib/String/Unique.pm',
    ABSTRACT_FROM       => 'lib/String/Unique.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Digest::MD5' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Unique-*' },
);
