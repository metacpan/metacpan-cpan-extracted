use ExtUtils::MakeMaker::CPANfile;


WriteMakefile(
    ABSTRACT          => 'Transport independent implementation of the OVSDB protocol (RFC 7047)',
    AUTHOR            => 'Erik Huelsmann <ehuels@gmail.com>',
    LICENSE           => 'perl_5',
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            bugtracker      => {
                web            => 'https://github.com/ehuelsmann/perl-protocol-ovsdb/issues',
            },
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ehuelsmann/perl-protocol-ovsdb.git',
                web            => 'https://github.com/ehuelsmann/perl-protocol-ovsdb',
            },
        },
    },
    NAME              => 'Protocol::OVSDB',
    VERSION_FROM      => 'lib/Protocol/OVSDB.pm',
);

