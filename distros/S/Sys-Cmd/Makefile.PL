#!/usr/bin/env perl
use v5.18;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'Sys::Cmd',
    MIN_PERL_VERSION => 5.018,
    ABSTRACT_FROM    => 'lib/Sys/Cmd.pm',
    AUTHOR           => 'Mark Lawrence <mark@rekudos.net>',
    VERSION_FROM     => 'lib/Sys/Cmd.pm',
    LICENSE          => 'gpl_3',
    test             => { RECURSIVE_TEST_FILES => 1, },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker =>
              { web => 'https://github.com/mlawren/p5-Sys-Cmd/issues' },
            homepage   => 'https://github.com/mlawren/p5-Sys-Cmd',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-Sys-Cmd.git',
                web  => 'https//github.com/mlawren/p5-Sys-Cmd',
            }
        },
        release_status => 'stable',
    },
);
