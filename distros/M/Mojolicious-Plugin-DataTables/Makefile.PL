use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Mojolicious::Plugin::DataTables',
    VERSION_FROM       => 'lib/Mojolicious/Plugin/DataTables.pm',
    ABSTRACT_FROM      => 'lib/Mojolicious/Plugin/DataTables.pm',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Mojolicious' => '7.93',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables',
                web  => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-DataTables'
            },
        }
    },
    test  => { TESTS    => 't/*.t' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Mojolicious-Plugin-DataTables-*' },
);
