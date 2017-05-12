use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Duowan::DNS',
    AUTHOR           => q{Ken Peng <yhpeng@cpan.org>},
    VERSION_FROM     => 'lib/Net/Duowan/DNS.pm',
    ABSTRACT_FROM    => 'lib/Net/Duowan/DNS.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'JSON' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Duowan-DNS-*' },
);
