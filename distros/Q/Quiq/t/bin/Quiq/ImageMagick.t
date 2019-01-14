#!/usr/bin/env perl

package Quiq::ImageMagick::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ImageMagick');
}

# -----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self = shift;

    my $cmd = Quiq::ImageMagick->new;
    $self->is(ref($cmd),'Quiq::ImageMagick');
}

# -----------------------------------------------------------------------------

sub test_addElement : Test(2) {
    my $self = shift;

    my $cmd = Quiq::ImageMagick->new;
    $cmd->addElement('input.jpg');
    $self->is($cmd->command,'input.jpg');
    
    $cmd = Quiq::ImageMagick->new;
    $cmd->addElement('Sonne am Abend.jpg');
    $self->is($cmd->command,q|'Sonne am Abend.jpg'|);
}
    

# -----------------------------------------------------------------------------

sub test_addOption : Test(2) {
    my $self = shift;

    my $cmd = Quiq::ImageMagick->new;
    $cmd->addOption('-negate');
    $self->is($cmd->command,'-negate');
    
    $cmd = Quiq::ImageMagick->new;
    $cmd->addOption(-rotate=>90);
    $self->is($cmd->command,q|-rotate 90|);
}
    

# -----------------------------------------------------------------------------

package main;
Quiq::ImageMagick::Test->runTests;

# eof
