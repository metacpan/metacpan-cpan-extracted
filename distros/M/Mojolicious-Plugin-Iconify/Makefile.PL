use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mojolicious::Plugin::Iconify',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/Iconify.pm',
    PREREQ_PM         => {'Mojolicious' => '1.78'},
    ABSTRACT_FROM     => 'lib/Mojolicious/Plugin/Iconify.pm',
    AUTHOR            => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    LICENSE           => 'artistic_2',
    MIN_PERL_VERSION  => 5.008,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify',
                web  => 'https://github.com/giterlizzi/perl-Mojolicious-Plugin-Iconify'
            },
        }
    },
    test  => { TESTS => 't/*.t' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-Iconify-*' },
);
