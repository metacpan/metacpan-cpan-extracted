#!/usr/bin/env perl

package Prty::TempFile::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TempFile');
}

# -----------------------------------------------------------------------------

sub test_new: Test(5) {
    my $self = shift;

    my $path;
    {
        my $file = Prty::TempFile->new;
        $path = "$file";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-f $file);
        $self->is(ref($file),'Prty::TempFile');
        $self->like($file,qr|^$tempDir/|);
        $self->like(sprintf('%s',$file),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

package main;
Prty::TempFile::Test->runTests;

# eof
