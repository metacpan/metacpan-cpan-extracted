#!/usr/bin/env perl

package Quiq::JQuery::Function::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::Function');
}

# -----------------------------------------------------------------------------

sub test_ready : Test(1) {
    my $self = shift;

    my $handler = Quiq::JQuery::Function->ready("alert('hello');");
    $self->isText("$handler\n",q~
        $(function() {
            alert('hello');
        });
    ~);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::Function::Test->runTests;

# eof
