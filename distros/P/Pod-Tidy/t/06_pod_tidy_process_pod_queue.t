#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: 06_pod_tidy_process_pod_queue.t,v 1.3 2005/10/03 01:15:56 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib ./t );

use Test::More tests => 11;

use File::Temp qw( tempdir );
use IO::String;
use Pod::Tidy;
use Test::Pod::Tidy;

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    $tmp_valid->flush;

    my $output;
    tie *STDOUT, 'IO::String', \$output;

    my $processed = Pod::Tidy::process_pod_queue(
        queue => [$tmp_valid->filename],
    );

    is($processed, 1, "number of files processed");
    is($output, $TIDY_POD, "reformatted file sent to STDOUT");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    $tmp_valid->flush;

    my $processed = Pod::Tidy::process_pod_queue(
        queue   => [$tmp_valid->filename],
        inplace => 1,
    );

    seek $tmp_valid, 0, 0;
    my $output = do { local $/; <$tmp_valid> };

    is($processed, 1, "number of files processed");
    ok(-e $tmp_valid->filename . $Pod::Tidy::BACKUP_POSTFIX,
        "created backup file");
    is($output, $TIDY_POD, "file reformatted in place");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    $tmp_valid->flush;

    my $processed = Pod::Tidy::process_pod_queue(
        queue       => [$tmp_valid->filename],
        inplace     => 1,
        nobackup    => 1,
    );

    seek $tmp_valid, 0, 0;
    my $output = do { local $/; <$tmp_valid> };

    is($processed, 1, "number of files processed");
    ok(!-e $tmp_valid->filename . $Pod::Tidy::BACKUP_POSTFIX,
        "no backup file created");
    is($output, $TIDY_POD, "file reformatted in place");
}

{
    my $processed = Pod::Tidy::process_pod_queue();

    is($processed, undef, "no params");
}

{
    my $processed= Pod::Tidy::process_pod_queue(
        queue => undef,
    );

    is($processed, undef, "queue param is undef");
}

{
    my $processed= Pod::Tidy::process_pod_queue(
        queue => [],
    );

    is($processed, 0, "queue param is undef");
}
