#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use ExtUtils::MakeMaker::CPANfile;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME         => 'SQL::Tree',
    ABSTRACT     => 'Generate a trigger-based SQL tree implementation',
    AUTHOR       => 'Mark Lawrence <nomad@null.net>',
    VERSION_FROM => 'lib/SQL/Tree.pm',
    LICENSE      => 'gpl_3',
    EXE_FILES    => ['bin/sqltree'],
    test         => {
        RECURSIVE_TEST_FILES => 1,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker =>
              { web => 'https//github.com/mlawren/sqltree/issues', },
            homepage   => 'https//github.com/mlawren/sqltree',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/sql-tree.git',
                web  => 'https//github.com/mlawren/sqltree',
            }
        },
    },
);

package MY;
use File::ShareDir::Install qw(postamble);

