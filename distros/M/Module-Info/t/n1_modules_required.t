#!/usr/bin/perl -w

use strict;
use lib './t/lib';
use Test::More tests => 3;
use lib '.';
use Module::Info;

my $bar = Module::Info->new_from_module( 'Bar' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 3 unless $] >= 5.006001;

    my %mods = $bar->modules_required;
    delete $mods{Win32} if $^O eq 'MSWin32';
    is_deeply( [ sort keys %mods ], [ sort qw(Cwd strict Carp) ],
               "Got the correct modules" );

    is_deeply( [ sort @{$mods{Cwd}} ], [ sort qw(1 1.00102 v1.1.2) ],
               "Got the correct versions when specified" );

    is_deeply( [], $mods{strict},
               "Got no version when not specified" );
}
