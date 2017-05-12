use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Net::Moip',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/Moip.pm',
    ABSTRACT_FROM       => 'lib/Net/Moip.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'               => 0.88,
        'IO::Socket::SSL'          => 0,
        'MIME::Base64'             => 0,
        'Furl'                     => 0,
        'String::CamelCase'        => 0,
        'XML::SAX::Writer'         => 0.56,
        'XML::Generator::PerlData' => 0.93,
        'Moo'                      => 0,
        'autovivification'         => 0,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-Moip/issues',
            repository  => 'http://github.com/garu/Net-Moip',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Moip-*' },
);


WriteMakefile( %options );

