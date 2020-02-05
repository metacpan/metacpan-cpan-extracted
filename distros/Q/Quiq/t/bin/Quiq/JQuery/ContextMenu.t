#!/usr/bin/env perl

package Quiq::JQuery::ContextMenu::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Json;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::ContextMenu');
}

# -----------------------------------------------------------------------------

sub test_js : Test(1) {
    my $self = shift;

    # JSON-Generator
    my $j = Quiq::Json->new;

    my $obj = Quiq::JQuery::ContextMenu->new(
        className => 'contextMenu',
        selector => '#mainMenu',
        trigger => 'left',
        callback => q~
            function(key,opt) {
                document.location = key;
            }
        ~,
        items => [
            taskSearch => $j->o(
                name => 'Auftrags-Monitor',
            ),
            jobMatrix => $j->o(
                name => 'Auftrags-Matrix',
            ),
            tree => $j->o(
                name => 'Abhängigkeits-Netz',
            ),
            runtime => $j->o(
                name => 'Job-Laufzeiten',
            ),
        ],
    );
    $self->is(ref($obj),'Quiq::JQuery::ContextMenu');

    my $js = $obj->js($j);
    # warn $js,"\n";
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::ContextMenu::Test->runTests;

# eof
