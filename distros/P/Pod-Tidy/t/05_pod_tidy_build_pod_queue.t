#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: 05_pod_tidy_build_pod_queue.t,v 1.6 2005/10/09 06:47:19 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib ./t );

use Test::More tests => 8;

use File::Temp qw( tempdir );
use Pod::Tidy;
use Test::Pod::Tidy;

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    my $queue = Pod::Tidy::build_pod_queue(
        files => [$tmp_valid->filename, $tmp_invalid->filename],
    );

    is_deeply($queue, [$tmp_valid->filename], "plain file list");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    my $queue = Pod::Tidy::build_pod_queue(
        files => [$dir],
    );

    # recusion is disabled by default
    is($queue, undef, "dir witht recursive disabled");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    my $queue = Pod::Tidy::build_pod_queue(
        files       => [$dir],
        recursive   => 1,
    );

    is_deeply($queue, [$tmp_valid->filename], "dir with recursive enabled");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_valid2  = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_valid2 $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_valid2->flush;
    $tmp_invalid->flush;

    my $queue = Pod::Tidy::build_pod_queue(
        files       => [$dir],
        recursive   => 1,
        ignore      => [qr/\Q$tmp_valid\E/],
    );

    is_deeply($queue, [$tmp_valid2->filename], "ignore 1 pattern");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_valid2  = File::Temp->new( DIR => $dir );
    my $tmp_valid3  = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $VALID_POD;
    print $tmp_valid2 $VALID_POD;
    print $tmp_valid3 $VALID_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_valid2->flush;
    $tmp_valid3->flush;
    $tmp_invalid->flush;

    my $queue = Pod::Tidy::build_pod_queue(
        files       => [$dir],
        recursive   => 1,
        ignore      => [qr/\Q$tmp_valid\E/, qr/\Q$tmp_valid2\E/],
    );

    is_deeply($queue, [$tmp_valid3->filename], "ignore 2 pattern");
}

# empty nested dirs
{
    my $dir         = tempdir( CLEANUP => 1 );
    my $dir2        = tempdir( DIR => $dir, CLEANUP => 1 );
    my $dir3        = tempdir( DIR => $dir2, CLEANUP => 1 );

    my $queue = Pod::Tidy::build_pod_queue(
        files       => [$dir],
        recursive   => 1,
    );

    is($queue, undef, "handles empty dirs");
}

{
    my $queue = Pod::Tidy::build_pod_queue();

    is($queue, undef, "no params");
}

{
    my $queue = Pod::Tidy::build_pod_queue(
        files => undef,
    );

    is($queue, undef, "files param is undef");
}
