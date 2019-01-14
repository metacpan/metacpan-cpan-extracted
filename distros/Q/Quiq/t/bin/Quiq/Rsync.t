#!/usr/bin/env perl

package Quiq::Rsync::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Rsync');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(2) {
    my $self = shift;

    my $srcDir = "/tmp/test-rsync-src-$$/";
    my $destDir = "/tmp/test-rsync-dest-$$";

    Quiq::Path->mkdir($srcDir);
    Quiq::Path->write("$srcDir/file1",'hello1');
        
    Quiq::Rsync->exec("$srcDir",$destDir);

    $self->ok(-d $destDir);
    $self->ok(-f "$destDir/file1");
    
    Quiq::Path->delete($srcDir);
    Quiq::Path->delete($destDir);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Rsync::Test->runTests;

# eof
