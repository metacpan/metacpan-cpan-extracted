use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Net::Backpack',
    AUTHOR             => q{Dave Cross <davecross@cpan.org>},
    VERSION_FROM       => 'lib/Net/Backpack.pm',
    ABSTRACT_FROM      => 'lib/Net/Backpack.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
    },
    PREREQ_PM            => {
        'HTTP::Request'  => 0,
        'LWP::UserAgent' => 0,
        'Test::More'     => 0,
        'XML::Simple'    => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Backpack-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/net-backpack.git',
                web  => 'https://github.com/manwar/net-backpack',
            },
        }})
     : ()
    ),
);
