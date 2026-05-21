use ExtUtils::MakeMaker 7.78;
use ExtUtils::MakeMaker::CPANfile;


WriteMakefile(
    ABSTRACT          => '',
    AUTHOR            => 'Erik Huelsmann <ehuels@gmail.com>',
    LICENSE           => 'perl_5',
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            bugtracker      => {
                web            => 'https://github.com/ehuelsmann/perl-sys-async-virt/issues',
            },
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ehuelsmann/perl-sys-async-virt.git',
                web            => 'https://github.com/ehuelsmann/perl-sys-async-virt',
            },
        },
    },
    NAME              => 'Sys::Async::Virt',
    VERSION_FROM      => 'lib/Sys/Async/Virt.pm', # EU::MM support 'class' statements with version numbers as of 7.78
);

