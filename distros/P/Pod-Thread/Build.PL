#!/usr/bin/perl
#
# Build script for Pod::Thread distribution.
#
# Copyright 2002, 2013, 2021 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.008;
use strict;
use warnings;

use Module::Build;

# Basic package configuration.
#<<<
my $build = Module::Build->new(
    module_name          => 'Pod::Thread',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    license              => 'mit',
    recursive_test_files => 1,

    # Add additional package metadata.
    meta_merge => {
        'meta-spec' => { version => '2' },
        resources   => {
            bugtracker => {
                web => 'https://github.com/rra/pod-thread/issues',
            },
            homepage   => 'https://www.eyrie.org/~eagle/software/pod-thread/',
            repository => {
                url  => 'https://github.com/rra/pod-thread.git',
                web  => 'https://github.com/rra/pod-thread',
                type => 'git',
            },
        },
    },

    # Other package relationships.
    configure_requires => { 'Module::Build' => 0.28 },
    test_requires      => { 'Perl6::Slurp'  => 0 },
    requires           => {
        'Pod::Simple' => '3.06',
        perl          => '5.024',
    },
);
#>>>

# Generate the build script.
$build->create_build_script;
