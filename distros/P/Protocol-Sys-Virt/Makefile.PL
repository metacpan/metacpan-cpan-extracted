use ExtUtils::MakeMaker::CPANfile;


WriteMakefile(
    ABSTRACT          => 'Transport independent implementation of the remote LibVirt protocol',
    AUTHOR            => 'Erik Huelsmann <ehuels@gmail.com>',
    LICENSE           => 'perl_5',
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            bugtracker      => {
                web            => 'https://github.com/ehuelsmann/perl-protocol-sys-virt/issues',
            },
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ehuelsmann/perl-protocol-sys-virt.git',
                web            => 'https://github.com/ehuelsmann/perl-protocol-sys-virt',
            },
        },
    },
    NAME              => 'Protocol::Sys::Virt',
    VERSION_FROM      => 'lib/Protocol/Sys/Virt.pm',
);

