#!/usr/bin/env perl

package Prty::Rsync::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Rsync');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(2) {
    my $self = shift;

    my $srcDir = "/tmp/test-rsync-src-$$/";
    my $destDir = "/tmp/test-rsync-dest-$$";

    Prty::Path->mkdir($srcDir);
    Prty::Path->write("$srcDir/file1",'hello1');
        
    Prty::Rsync->exec("$srcDir",$destDir);

    $self->ok(-d $destDir);
    $self->ok(-f "$destDir/file1");
    
    Prty::Path->delete($srcDir);
    Prty::Path->delete($destDir);
}

# -----------------------------------------------------------------------------

package main;
Prty::Rsync::Test->runTests;

# eof
