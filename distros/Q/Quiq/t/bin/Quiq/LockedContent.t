#!/usr/bin/env perl

package Quiq::LockedContent::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::LockedContent');
}

# -----------------------------------------------------------------------------

sub test_unitTest_root: Test(4) {
    my $self = shift;

    my $p = Quiq::Path->new;

    my $file = $p->tempFile;
    my $obj = Quiq::LockedContent->new($file);
    $self->is(ref($obj),'Quiq::LockedContent');

    my $data = $obj->read;
    $self->is($data,'');

    $obj->write('ABC');
    $data = $obj->read;
    $self->is($data,'ABC');

    $obj->close;
    $self->is($obj,undef);

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::LockedContent::Test->runTests;

# eof
