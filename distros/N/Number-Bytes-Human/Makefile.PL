#!/usr/bin/perl
use 5.006;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Number::Bytes::Human',
    VERSION_FROM      => 'Human.pm', # finds $VERSION
    PREREQ_PM         => {
        POSIX                    => 0,
        Carp                     => 0,
        Test::More               => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'Human.pm', # retrieve abstract from module
       AUTHOR         => 'A. R. Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl',
    ) :()),
    ($EUMM_VERSION > 6.4501 ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'git://github.com/aferreira/cpan-Number-Bytes-Human.git',
                    web => 'https://github.com/aferreira/cpan-Number-Bytes-Human',
                }
            },
            prereqs => {
                test => {
		    requires => {
                        'Test::More'          => 0,
                    },
		    recommends => {
                        'Test::Pod'           => '1.18',
                        'Test::Pod::Coverage' => '1.04',
                    },
                }
            },
        },
    ) : ()),
);
