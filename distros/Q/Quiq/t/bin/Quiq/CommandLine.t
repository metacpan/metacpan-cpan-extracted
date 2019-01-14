#!/usr/bin/env perl

package Quiq::CommandLine::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::CommandLine;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::CommandLine');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(5) {
    my $self = shift;

    my $c = Quiq::CommandLine->new;
    $self->isClass($c,'Quiq::CommandLine');
    $self->is($c->{'cmd'},'');

    $c = Quiq::CommandLine->new('iconv');
    $c->addOption(
        -f => 'utf-8',
        -t => 'latin1',
    );
    $c->addString('|',"enscript --header=''");
    $c->addBoolOption(
        '--landscape' => 1,
    );
    $c->addLongOption(
        '--font' => 'Courier8',
    );
    $c->addString('2>/dev/null','|','ps2pdf','-');
    $c->addArgument('/tmp/test.pdf');

    my $cmd = $c->command;
    $self->is($cmd,q{iconv -f utf-8 -t latin1 | enscript --header=''}.
        qq{ --landscape --font=Courier8 2>/dev/null | ps2pdf - /tmp/test.pdf});

    # Methode value()
    
    my $val = Quiq::CommandLine->value(undef);
    $self->is($val,undef);
    
    $val = Quiq::CommandLine->value('');
    $self->is($val,"''");
    
    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::CommandLine::Test->runTests;

# eof
