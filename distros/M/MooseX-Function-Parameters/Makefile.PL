#!/usr/bin/env perl
use strict;
use warnings;
use 5.008;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'MooseX::Function::Parameters',
    AUTHOR       => 'Rob Farr <robfarr@cpan.org>',
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/MooseX/Function/Parameters.pm',
    PREREQ_PM    => {
        'strictures'           => '2',
        'Const::Fast'          => '0',
        'Function::Parameters' => '1',
        'Moose'                => '0',
    },
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://github.com/robfarr/perl-MooseX-Function-Parameters',
            repository => {
                type => 'git',
                url  => 'git@github.com:robfarr/perl-MooseX-Function-Parameters.git',
                web  => 'https://github.com/robfarr/perl-MooseX-Function-Parameters',
            },
            bugtracker => {
                web  => 'https://github.com/robfarr/perl-MooseX-Function-Parameters/issues',
            },
        },
    },
);
