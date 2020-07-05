#!/usr/bin/perl
#
# Build script for the PGP::Sign distribution.
#
# Copyright 2018, 2020 Russ Allbery <rra@cpan.org>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

use 5.020;
use autodie;
use strict;
use warnings;

use Module::Build;

# Basic package configuration.
my $build = Module::Build->new(
    module_name          => 'PGP::Sign',
    dist_author          => 'Russ Allbery <rra@cpan.org>',
    license              => 'perl',
    recursive_test_files => 1,
    add_to_cleanup =>
      [qw(MANIFEST.bak cover_db t/data/random_seed t/data/trustdb.gpg)],

    # Other package relationships.
    configure_requires => { 'Module::Build' => 0.28 },
    requires           => {
        'IPC::Run' => 0,
        'perl'     => '5.020',
    },
);

# Generate the build script.
$build->create_build_script();
