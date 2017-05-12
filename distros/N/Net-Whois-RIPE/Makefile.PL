use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Whois::RIPE',
    AUTHOR           => 'Luis Motta Campos <lmc@cpan.org>',
    VERSION_FROM     => 'lib/Net/Whois/RIPE.pm',
    ABSTRACT_FROM    => 'lib/Net/Whois/RIPE.pm',
    MIN_PERL_VERSION => 5.006,
    PL_FILES         => {},
    PREREQ_PM        => {
                   'Test::More'     => 0,
                   'Iterator'       => 0,
    },
    META_MERGE => {
        recommends => {
                    'LWP::UserAgent' => 0,
        },
        resources => { 
                        repository => 'https://github.com/arhuman/Net-Whois-RIPE',
                        bugtracker => 'https://github.com/arhuman/Net-Whois-RIPE/issues'
        },
    },
    BUILD_REQUIRES => { },
    dist           => { COMPRESS          => 'gzip -9f', SUFFIX => 'gz', },
    clean          => { FILES             => 'Net-Whois-RIPE-*' },
);
