use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported!\n";
}

unless ( $Config{useithreads} ) {
    die "Your perl is not compiled with the 'useithreads' option!\n";
}

WriteMakefile(
    NAME             => 'Mojo::Server::Threaded',
    AUTHOR           => q{Thomas Kratz <TOMK@cpan.org>},
    VERSION_FROM     => 'lib/Mojo/Server/Threaded.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Server/Threaded.pm',
    LICENSE          => 'artistic_2',
    EXE_FILES        => ['script/elzar'],
    MIN_PERL_VERSION => 5.010001,
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.010001'}}},
        resources      => {
            bugtracker => {web => 'https://github.com/tomk3003/mojo-server-threaded/issues'},
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {
                type => 'git',
                url  => 'https://github.com/tomk3003/mojo-server-threaded.git',
                web  => 'https://github.com/tomk3003/mojo-server-threaded',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        Mojolicious      => 7.35,
        'Win32::Process' => 0.14,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Server-Threaded-*' },
);
