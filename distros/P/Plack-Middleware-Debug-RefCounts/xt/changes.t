#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use Test::CPAN::Changes;

use File::Find;
use Module::Metadata;

my @pm_files;
find(sub { push @pm_files, $File::Find::name if /\.pm$/}, 'lib');

my $main_module_info = Module::Metadata->new_from_file('lib/Plack/Middleware/Debug/RefCounts.pm');
changes_file_ok( 'CHANGES', { version => $main_module_info->version->stringify } );

foreach my $pm_file (@pm_files) {
    my $info = Module::Metadata->new_from_file($pm_file);
    next if $info->filename eq $main_module_info->filename;

    # Cmp_ok will try to run a math operation (ie: "$got + 0") for numeric comparisons,
    # which is illegal in version.  So, fallback to numify.
    cmp_ok(
        $main_module_info->version->numify,
        '==',
        $info->version->numify,
        "Version from ".$info->name." matches ".$main_module_info->name
    );
}

done_testing;
