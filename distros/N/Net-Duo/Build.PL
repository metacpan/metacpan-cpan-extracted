#!/usr/bin/perl
#
# Build script for the Net::Duo distribution.
#
# Written by Russ Allbery <rra@cpan.org>
# Copyright 2014
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

use 5.014;
use strict;
use warnings;

use Module::Build;

# Basic package configuration.
my $build = Module::Build->new(
    module_name          => 'Net::Duo',
    dist_abstract        => 'API for Duo multifactor authentication service',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    dist_version         => '1.01',
    license              => 'mit',
    recursive_test_files => 1,

    # Add additional package metadata.
    meta_merge => {
        resources => {
            repository => 'git://git.eyrie.org/perl/duo.git',
            bugtracker =>
              'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-Duo',
        },
    },

    # Other package relationships.
    configure_requires => { 'Module::Build' => 0.28 },
    requires           => {
        JSON             => 0,
        'LWP::UserAgent' => '6.00',
        'Perl6::Slurp'   => 0,
        'Sub::Install'   => 0,
        'URI::Escape'    => 0,
        perl             => '5.014'
    },
);

# Generate the build script.
$build->create_build_script;
