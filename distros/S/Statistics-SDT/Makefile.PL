use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::SDT',
    AUTHOR              => 'Roderick Garton <rgarton@cpan.org>',
    VERSION_FROM        => 'lib/Statistics/SDT.pm',
    ABSTRACT_FROM       => 'lib/Statistics/SDT.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Math::Cephes' => 0.44,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-SDT-0.50-*' },
);
