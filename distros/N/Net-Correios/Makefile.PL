use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Net::Correios',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/Correios.pm',
    ABSTRACT_FROM       => 'lib/Net/Correios.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test2::V0'    => 0,
        'HTTP::Tiny'   => 0,
        'MIME::Base64' => 0,
        'Carp'         => 0,
        'Scalar::Util' => 0,
        'JSON'         => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-Correios/issues/',
            repository  => 'https://github.com/garu/Net-Correios',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Correios-*' },
);

WriteMakefile( %options );
