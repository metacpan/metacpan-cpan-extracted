use v5.10; use strict; use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Proxy::Impersonate',
    VERSION_FROM     => 'lib/Proxy/Impersonate.pm',
    ABSTRACT         => 'EV MITM proxy that re-originates with a browser TLS/HTTP2 fingerprint',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => { 'EV' => 0, 'Net::SSLeay' => '1.85', 'Curl::Impersonate' => '0.03', 'File::Temp' => '0.19' },
    TEST_REQUIRES    => { 'Test::More' => '0.88' },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-proxy-impersonate.git',
                web  => 'https://github.com/vividsnow/perl5-proxy-impersonate',
            },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-proxy-impersonate/issues' },
        },
        (eval { require Module::Metadata; 1 }
            ? (provides => Module::Metadata->provides(version => 2, dir => 'lib'))
            : ()),
    },
);

# README is generated, never edited -- a hand-kept one drifts from the POD.
# create_distdir, not distdir: distdir's prerequisites are built left to right,
# so create_distdir would copy the files before README was regenerated.
sub MY::postamble {
    return <<"MAKE";

readme : README

README : lib/Proxy/Impersonate.pm
\t\$(PERLRUN) -MPod::Text -e "Pod::Text->new->parse_from_file(q{lib/Proxy/Impersonate.pm}, q{README})"

create_distdir : README

MAKE
}
