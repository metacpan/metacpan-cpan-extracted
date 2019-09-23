#!/usr/bin/env perl

package Quiq::TempFile::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TempFile');
}

# -----------------------------------------------------------------------------

sub test_new: Test(5) {
    my $self = shift;

    my $path;
    {
        my $file = Quiq::TempFile->new;
        $path = "$file";
        my $tempDir = $ENV{'TMPDIR'};
        if (!defined($tempDir) || !-d $tempDir) {
            $tempDir = '/tmp';
        }
        $self->ok(-f $file);
        $self->is(ref($file),'Quiq::TempFile');
        $self->like($file,qr|^$tempDir/|);
        $self->like(sprintf('%s',$file),qr|^$tempDir/|);
    }
    $self->ok(!-d $path);
}

# -----------------------------------------------------------------------------

package main;
Quiq::TempFile::Test->runTests;

# eof
