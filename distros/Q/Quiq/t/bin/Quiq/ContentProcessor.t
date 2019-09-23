#!/usr/bin/env perl

package Quiq::ContentProcessor::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Perl;
use Quiq::Section::Object;
use Quiq::Path;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ContentProcessor');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $storage = '/tmp/.storage';
    
    # Instantiierung
    
    my $cop = Quiq::ContentProcessor->new($storage);
    $self->is(ref($cop),'Quiq::ContentProcessor');

    # Objektattribute
    
    my $val = $cop->get('storage');
    $self->is($val,'/tmp/.storage');

    # Type-Plugin

    Quiq::Perl->createClass('MyTool::Program::Shell');
    
    $cop->registerType('MyTool::Program::Shell','xprg','Program',
        'Program',Language=>'Shell');

    # * positiver Fall
    
    my $sec = Quiq::Section::Object->new('[Program]',{Language=>'Shell'});
    my $plg = $cop->plugin($sec);
    $self->ok($plg);

    # * negativer Fall
    
    $sec = Quiq::Section::Object->new('[Program]',{Language=>'Perl'});
    $plg = $cop->plugin($sec);
    $self->is($plg,undef);

    # aufräumen
    
    Quiq::Path->delete($storage);
}

# -----------------------------------------------------------------------------

package main;
Quiq::ContentProcessor::Test->runTests;

# eof
