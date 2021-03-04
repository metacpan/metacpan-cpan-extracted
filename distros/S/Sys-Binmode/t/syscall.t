#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;

eval { require Linux::Seccomp } or do {
    plan skip_all => 'This test needs Linux::Seccomp.';
};

my $rmdir_num = Linux::Seccomp::syscall_resolve_name("rmdir");

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e = "é";

mkdir "$dir/$e";

my $e_up = $e;
utf8::upgrade $e_up;

{
    use Sys::Binmode;
    syscall $rmdir_num, "$dir/$e_up";
}

my $err = $!;

ok( !(-e "$dir/$e"), 'syscall with upgraded string' ) or diag "err: $err";

done_testing;

1;
