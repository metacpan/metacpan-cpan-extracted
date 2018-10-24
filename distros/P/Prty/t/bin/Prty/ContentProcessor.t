#!/usr/bin/env perl

package Prty::ContentProcessor::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

use Prty::Perl;
use Prty::Section::Object;
use Prty::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::ContentProcessor');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $storage = '/tmp/.storage';
    
    # Instantiierung
    
    my $cop = Prty::ContentProcessor->new($storage);
    $self->is(ref($cop),'Prty::ContentProcessor');

    # Objektattribute
    
    my $val = $cop->get('storage');
    $self->is($val,'/tmp/.storage');

    # Type-Plugin

    Prty::Perl->createClass('MyTool::Program::Shell');
    
    $cop->registerType('MyTool::Program::Shell','xprg','Program',
        'Program',Language=>'Shell');

    # * positiver Fall
    
    my $sec = Prty::Section::Object->new('[Program]',{Language=>'Shell'});
    my $plg = $cop->plugin($sec);
    $self->ok($plg);

    # * negativer Fall
    
    $sec = Prty::Section::Object->new('[Program]',{Language=>'Perl'});
    $plg = $cop->plugin($sec);
    $self->is($plg,undef);

    # aufräumen
    
    Prty::Path->delete($storage);
}

# -----------------------------------------------------------------------------

package main;
Prty::ContentProcessor::Test->runTests;

# eof
