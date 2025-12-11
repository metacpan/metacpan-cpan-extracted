#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME       => 'OptArgs2',
    ABSTRACT   => 'CLI argument and option processing',
    AUTHOR     => 'Mark Lawrence <nomad@null.net>',
    VERSION    => 'v2.0.17',
    LICENSE    => 'gpl_3',
    test       => { RECURSIVE_TEST_FILES => 1, },
    META_MERGE => {
        dynamic_config => 1,
        'meta-spec'    => { version => 2 },
        no_index       => {
            package => [
                qw/
                  OptArgs2::CODEREF
                  OptArgs2::Status
                  /
            ],
        },
        resources => {
            bugtracker =>
              { web => 'https://github.com/mlawren/p5-OptArgs/issues', },
            homepage   => 'https://github.com/mlawren/p5-OptArgs',
            repository => {
                type => 'git',
                url  => 'ssh://git@github.com/mlawren/p5-OptArgs.git',
                web  => 'https//github.com/mlawren/p5-OptArgs',
            }
        },
        release_status => 'stable',
    },
);

