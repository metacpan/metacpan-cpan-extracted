#!/usr/bin/env perl

package Prty::TempDir::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TempDir');
}

# -----------------------------------------------------------------------------

sub test_new: Test(5) {
    my $self = shift;

    my $path;
    {
        my $dir = Prty::TempDir->new;
        $path = "$dir";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-d $dir);
        $self->is(ref($dir),'Prty::TempDir');
        $self->like($dir,qr|^$tempDir/|);
        $self->like(sprintf('%s',$dir),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

package main;
Prty::TempDir::Test->runTests;

# eof
