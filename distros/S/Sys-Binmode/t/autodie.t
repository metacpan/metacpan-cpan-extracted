#!/usr/bin/env perl

use strict;
use warnings;

use autodie ('chmod');

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Errno;
use Fcntl;
use Config;

$| = 1;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $e_down = "é";
utf8::downgrade($e_down);

my $e_up = $e_down;
utf8::upgrade($e_up);

open my $wfh, '>', "$dir/$e_down";

sub _get_path_up { "$dir/$e_up" }

{
    use Sys::Binmode;

    eval { chmod 0644, _get_path_up() or die $! };
    my $err = $@;

  TODO: {
        local $TODO = 'autodie bug';
        is( $err, q<>, 'chmod() with upgraded string' ) or diag $err;
    }
}

done_testing();

1;
