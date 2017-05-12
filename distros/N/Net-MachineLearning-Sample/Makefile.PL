use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::MachineLearning::Sample',
    AUTHOR           => q{Ken Peng <yhpeng@cpan.org>},
    VERSION_FROM     => 'lib/Net/MachineLearning/Sample.pm',
    ABSTRACT_FROM    => 'lib/Net/MachineLearning/Sample.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
		JSON => 0,
		GD => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-MachineLearning-Sample-*' },
);
