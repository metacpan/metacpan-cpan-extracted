use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::SNTP::Server',
    AUTHOR           => q{Athanasios Garyfalos <garyfalos@cpan.org>},
    VERSION_FROM     => 'lib/Net/SNTP/Server.pm',
    ABSTRACT_FROM    => 'lib/Net/SNTP/Server.pm',
    LICENSE          => 'Artistic_2_0',
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
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-SNTP-Server-*' },
    META_MERGE => {
        'meta-spec' => { version => 6 },
	    resources => {
		repository => {
		    type => 'git',
		    url  => 'https://github.com/thanos1983/perl5-Net-SNTP-Server.git',
		    web  => 'https://github.com/thanos1983/perl5-Net-SNTP-Server',
		},
	},
    },
    );
