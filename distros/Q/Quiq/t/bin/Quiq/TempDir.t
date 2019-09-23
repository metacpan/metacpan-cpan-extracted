#!/usr/bin/env perl

package Quiq::TempDir::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TempDir');
}

# -----------------------------------------------------------------------------

sub test_new: Test(5) {
    my $self = shift;

    my $path;
    {
        my $dir = Quiq::TempDir->new;
        $path = "$dir";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-d $dir);
        $self->is(ref($dir),'Quiq::TempDir');
        $self->like($dir,qr|^$tempDir/|);
        $self->like(sprintf('%s',$dir),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

package main;
Quiq::TempDir::Test->runTests;

# eof
