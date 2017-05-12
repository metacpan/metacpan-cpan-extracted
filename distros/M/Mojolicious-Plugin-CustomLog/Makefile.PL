use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    LICENSE      => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/JingxuanWang/Mojolicious-Plugin-CustomLog.git',
                 web  => 'https://github.com/JingxuanWang/Mojolicious-Plugin-CustomLog',
             },
         },
    },
    NAME         => 'Mojolicious::Plugin::CustomLog',
    VERSION_FROM => 'lib/Mojolicious/Plugin/CustomLog.pm',
    AUTHOR       => 'Jingxuan Wang <wjx@cpan.org>',
    PREREQ_PM    => {'Mojolicious' => '6.55'},
    test         => {TESTS => 't/*.t'}
);
