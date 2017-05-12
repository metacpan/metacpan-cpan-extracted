#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mutex;

{
    my $mutex = Mutex->new( impl => 'Flock' );

    is( $mutex->impl(), 'Flock', 'implementation name 1' );
}
{
    my ($tmp_dir, $tmp_file);

    if ($ENV{TEMP} && -d $ENV{TEMP} && -w _) {
        $tmp_dir = $ENV{TEMP};
    }
    elsif ($ENV{TMPDIR} && -d $ENV{TMPDIR} && -w _) {
        $tmp_dir = $ENV{TMPDIR};
    }
    elsif (-d '/tmp' && -w _) {
        $tmp_dir = '/tmp';
    }
    else {
        done_testing;
        exit;
    }

    $tmp_dir =~ s{/$}{};

    # remove tainted'ness from $tmp_dir
    if ($^O eq 'MSWin32') {
        ($tmp_file) = "$tmp_dir\\lockfile.$$.lock" =~ /(.*)/;
    } else {
        ($tmp_file) = "$tmp_dir/lockfile.$$.lock" =~ /(.*)/;
    }

    my $mutex = Mutex->new( path => $tmp_file );

    is( $mutex->impl(), 'Flock', 'implementation name 2' );

    unlink $tmp_file;
}

done_testing;

