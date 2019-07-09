#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'MojoX::JSON::RPC',
    VERSION_FROM => 'lib/MojoX/JSON/RPC.pm',
    ABSTRACT     => 'Perl implementation of JSON-RPC 2.0 protocol for Mojolicious',
    AUTHOR       => 'Henry Tang <henryykt@gmail.com>',
    PREREQ_PM    => { 'Mojolicious' => '7.13' },
    LICENSE      => 'artistic_2',
    test         => { TESTS => 't/*.t t/*/*.t t/*/*/*.t' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/dk/MojoX-JSON-RPC.git',
                web => 'https://github.com/dk/MojoX-JSON-RPC',
            },
        },
    },
);
