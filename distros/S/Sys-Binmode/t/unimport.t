#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Errno;
use Fcntl;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e_down = "é";
utf8::downgrade($e_down);

my $e_up = $e_down;
utf8::upgrade($e_up);

open my $wfh, '>', "$dir/$e_down";

sub _get_path_up { "$dir/$e_up" }

if ( open my $rfh, '<', _get_path_up() ) {
    plan skip_all => 'This module seems unneeded?';
}
else {
    use Sys::Binmode;

    {
        no Sys::Binmode;

        ok(
            !open( my $rfh, '<', _get_path_up() ),
            'unimport works as intended',
        );
    }
}

done_testing;
