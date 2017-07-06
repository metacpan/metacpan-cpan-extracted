use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::ZooIt',
    VERSION_FROM => 'lib/Net/ZooIt.pm',
    ABSTRACT_FROM => 'lib/Net/ZooIt.pm',
    LICENSE => 'apache_2_0',
    AUTHOR => 'SZABO Gergely <szg@subogero.com>',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        Carp => 0,
        Exporter => 0,
        'File::Temp' => 0,
        FindBin => 0,
        'Net::ZooKeeper' => 0,
        POSIX => 0,
        'Pod::Markdown' => 0,
        'Sys::Hostname' => 0,
        'Time::HiRes' => 0,
        base => 0,
        feature => 0,
        strict => 0,
        warnings => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                web => "https://github.com/subogero/libnet-zooit-perl",
                url => "https://github.com/subogero/libnet-zooit-perl.git",
                type => 'git',
            },
        },
    },
);


sub MY::postamble {
    return <<'EOF';
all :: README
README :: lib/Net/ZooIt.pm Makefile
	bin/pod2md -o $@ $<
export VERSION
release ::
	bin/release prepare
	touch Makefile.PL
tag ::
	bin/release finish
	$(MAKE) dist
EOF
}
