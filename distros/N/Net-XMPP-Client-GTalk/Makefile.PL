use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::XMPP::Client::GTalk',
    AUTHOR           => q{Harish Madabushi <harish.tmh@gmail.com>},
    VERSION_FROM     => 'lib/Net/XMPP/Client/GTalk.pm',
    ABSTRACT_FROM    => 'lib/Net/XMPP/Client/GTalk.pm',
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
	'Net::XMPP'         => 0     ,
	'XML::Smart'        => 0     ,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-XMPP-Client-GTalk-*' },
);
