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
        'Test::More' => '0.92',
		'List::AllUtils'  => '0.09',
        'Math::Cephes'    => '0.5304',
        'String::Numeric' => '0.9',
        'String::Util' => '1.21',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-SDT-0.06-*' },
);
