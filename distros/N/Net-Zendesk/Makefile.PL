use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Net::Zendesk',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/Zendesk.pm',
    ABSTRACT_FROM       => 'lib/Net/Zendesk.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'MIME::Base64'    => 0,
        'URI::Escape'     => 0,
        'Furl'            => 0,
        'IO::Socket::SSL' => 0,
        'Test::More'      => 0.88,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-Zendesk/issues/',
            repository  => 'https://github.com/garu/Net-Zendesk',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Zendesk-*' },
);


WriteMakefile( %options );

