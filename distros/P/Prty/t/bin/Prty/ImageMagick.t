#!/usr/bin/env perl

package Prty::ImageMagick::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ImageMagick');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $cmd = Prty::ImageMagick->new;
    $self->is(ref($cmd),'Prty::ImageMagick');
}

# -----------------------------------------------------------------------------

sub test_addElement : Test(2) {
    my $self = shift;

    my $cmd = Prty::ImageMagick->new;
    $cmd->addElement('input.jpg');
    $self->is($cmd->command,'input.jpg');
    
    $cmd = Prty::ImageMagick->new;
    $cmd->addElement('Sonne am Abend.jpg');
    $self->is($cmd->command,q|'Sonne am Abend.jpg'|);
}
    

# -----------------------------------------------------------------------------

sub test_addOption : Test(2) {
    my $self = shift;

    my $cmd = Prty::ImageMagick->new;
    $cmd->addOption('-negate');
    $self->is($cmd->command,'-negate');
    
    $cmd = Prty::ImageMagick->new;
    $cmd->addOption(-rotate=>90);
    $self->is($cmd->command,q|-rotate 90|);
}
    

# -----------------------------------------------------------------------------

package main;
Prty::ImageMagick::Test->runTests;

# eof
