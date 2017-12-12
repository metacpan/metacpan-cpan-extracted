#!/usr/bin/env perl

package Prty::CommandLine::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::CommandLine');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    my $c = Prty::CommandLine->new;
    $self->isClass($c,'Prty::CommandLine');
    $self->is($c->{'cmd'},'');

    $c = Prty::CommandLine->new('iconv');
    $c->addOption(
        -f => 'utf-8',
        -t => 'latin1',
    );
    $c->addString('|',"enscript --header=''");
    $c->addBoolOption(
        '--landscape' => 1,
    );
    $c->addOption(
        '--font' => 'Courier8',
    );
    $c->addString('2>/dev/null','|','ps2pdf','-');
    $c->addArgument('/tmp/test.pdf');

    my $cmd = $c->command;
    $self->is($cmd,q{iconv -f utf-8 -t latin1 | enscript --header=''}.
        qq{ --landscape --font=Courier8 2>/dev/null | ps2pdf - /tmp/test.pdf});

    # Methode value()
    
    my $val = Prty::CommandLine->value(undef);
    $self->is($val,undef);
    
    $val = Prty::CommandLine->value('');
    $self->is($val,"''");
    
    return;
}

# -----------------------------------------------------------------------------

package main;
Prty::CommandLine::Test->runTests;

# eof
