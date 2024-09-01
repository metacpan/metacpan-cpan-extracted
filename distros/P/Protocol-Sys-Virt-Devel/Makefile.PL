use ExtUtils::MakeMaker::CPANfile;


WriteMakefile(
    ABSTRACT          => 'Development helper for Protocol::Sys::Virt and its dependants',
    AUTHOR            => 'Erik Huelsmann <ehuels@gmail.com>',
    LICENSE           => 'perl_5',
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ehuelsmann/perl-protocol-sys-virt-devel.git',
                web            => 'https://github.com/ehuelsmann/perl-protocol-sys-virt-devel',
            },
        },
    },
    NAME              => 'Protocol::Sys::Virt::Devel',
    VERSION_FROM      => 'lib/Protocol/Sys/Virt/Devel.pm',
);

