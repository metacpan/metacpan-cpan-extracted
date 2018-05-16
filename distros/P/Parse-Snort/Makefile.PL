use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Snort',
    AUTHOR              => 'Richard <perl-cpan@richardharman.com>',
    VERSION_FROM        => 'lib/Parse/Snort.pm',
    ABSTRACT_FROM       => 'lib/Parse/Snort.pm',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.008009',
    TEST_REQUIRES => {
        'Test::Exception' => 0,
        'Test::More'      => 0.82,
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Class::Accessor' => 0,
        'List::Util'      => 1.33,
        'Sub::Util'       => 1.40,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Snort-*' },
);
