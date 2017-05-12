use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = (
    NAME                => 'Net::TinyERP',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Net/TinyERP.pm',
    ABSTRACT_FROM       => 'lib/Net/TinyERP.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0.88,
        'Test::Fatal'     => 0,
        'IO::Socket::SSL' => 0,
        'Scalar::Util'    => 0,
        'Furl'            => 0,
        'JSON::MaybeXS'   => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Net-TinyERP/issues/',
            repository  => 'https://github.com/garu/Net-TinyERP',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-TinyERP-*' },
);


if ($^O =~ /Win32/i) {
    $options{PREREQ_PM}{'Win32::Console::ANSI'} = 1.0;
}


WriteMakefile( %options );

