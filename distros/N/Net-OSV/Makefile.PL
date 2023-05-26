use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

my %options = (
    NAME                => 'Net::OSV',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/OSV.pm',
    ABSTRACT_FROM       => 'lib/Net/OSV.pm',
    MIN_PERL_VERSION => 5.020000,
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Carp'            => 0,
        'JSON'            => 0,
        'HTTP::Tiny'      => 0,
        'IO::Socket::SSL' => 1.56,
        'Net::SSLeay'     => 1.49,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-OSV/issues/',
            repository  => 'https://github.com/garu/Net-OSV',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-NVD-*' },
);

WriteMakefile( %options );
