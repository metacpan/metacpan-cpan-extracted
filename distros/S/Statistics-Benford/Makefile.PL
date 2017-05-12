use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'Statistics::Benford',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Statistics/Benford.pm',
    ABSTRACT_FROM => 'lib/Statistics/Benford.pm',
    PREREQ_PM     => {
        'List::Util' => 0,
        'Test::More' => 0,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/statistics-benford',
        }
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Statistics-Benford-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);
