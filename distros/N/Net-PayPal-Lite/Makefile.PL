use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Net::PayPal::Lite',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/PayPal/Lite.pm',
    ABSTRACT_FROM       => 'lib/Net/PayPal/Lite.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Carp'            => 0,
        'LWP::UserAgent'  => 0,
        'HTTP::Headers'   => 0,
        'HTTP::Request'   => 0,
        'JSON'            => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-PayPal-Lite/issues/',
            repository  => 'https://github.com/garu/Net-PayPal-Lite',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-PayPal-Lite-*' },
);

WriteMakefile( %options );
