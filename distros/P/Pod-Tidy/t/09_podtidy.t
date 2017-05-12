#!/usr/bin/env perl

# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: 09_podtidy.t,v 1.4 2005/10/05 01:09:31 jhoblitt Exp $

use strict;
use warnings;

use lib qw( ./lib ./t );

use Test::More tests => 38;

use File::Temp qw( tempdir );
use Pod::Tidy;
use Test::Cmd;
use Test::Pod::Tidy;

my $cmd = Test::Cmd->new(prog => "$^X scripts/podtidy", workdir => '');
isa_ok($cmd, 'Test::Cmd');

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    my @files = ( $tmp_valid->filename, $tmp_invalid->filename);

    $cmd->run(args => join " ", @files);

    cmd_output($cmd, 0, qr/^\Q$TIDY_POD\E$/, qr/^$/);
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "$dir");

    # recusion is disabled by default
    cmd_output($cmd, 0, qr/^$/, qr/^$/);
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-r $dir");

    cmd_output($cmd, 0, qr/^\Q$TIDY_POD\E$/, qr/^$/);
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-ri $dir");

    seek $tmp_valid, 0, 0;
    my $output = do { local $/; <$tmp_valid> };
    
    cmd_output($cmd, 0, qr/^$/, qr/^$/);
    ok(-e $tmp_valid->filename . $Pod::Tidy::BACKUP_POSTFIX,
        "created backup file");
    is($output, $TIDY_POD, "file reformatted in place");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-rin $dir");

    seek $tmp_valid, 0, 0;
    my $output = do { local $/; <$tmp_valid> };

    cmd_output($cmd, 0, qr/^$/, qr/^$/);
    ok(!-e $tmp_valid->filename . $Pod::Tidy::BACKUP_POSTFIX,
        "created backup file");
    is($output, $TIDY_POD, "file reformatted in place");
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_valid2  = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_valid2 $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_valid2->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-r $dir");

    seek $tmp_valid, 0, 0;
    my $output = do { local $/; <$tmp_valid> };

    cmd_output($cmd, 0, qr/^\Q$TIDY_POD$TIDY_POD\E$/, qr/^$/);
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_valid2  = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_valid2 $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_valid2->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-r $dir -I $tmp_valid");

    cmd_output($cmd, 0, qr/^\Q$TIDY_POD\E$/, qr/^$/);
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $tmp_valid   = File::Temp->new( DIR => $dir );
    my $tmp_valid2  = File::Temp->new( DIR => $dir );
    my $tmp_valid3  = File::Temp->new( DIR => $dir );
    my $tmp_invalid = File::Temp->new( DIR => $dir );

    print $tmp_valid $MESSY_POD;
    print $tmp_valid2 $MESSY_POD;
    print $tmp_valid3 $MESSY_POD;
    print $tmp_invalid $INVALID_POD;
    $tmp_valid->flush;
    $tmp_valid2->flush;
    $tmp_valid3->flush;
    $tmp_invalid->flush;

    $cmd->run(args => "-r $dir -I $tmp_valid -I $tmp_valid2");

    cmd_output($cmd, 0, qr/^\Q$TIDY_POD\E$/, qr/^$/);
}

# XXX -h is broken
$cmd->run(args => '--h');
cmd_output($cmd, 0, qr/^Usage/, qr/^$/);

$cmd->run(args => '-?');
cmd_output($cmd, 0, qr/^Usage/, qr/^$/);

$cmd->run(args => '--help');
cmd_output($cmd, 0, qr/^Usage/, qr/^$/);

sub cmd_output
{
    my ($cmd, $exit, $stdout, $stderr) = @_;

    is($? >> 8, $exit, "error code is: $exit");
    like($cmd->stdout, $stdout, "stdout string");
    like($cmd->stderr, $stderr, "stderr string");
}
