#!/usr/bin/env perl

package Quiq::Css::Snippets::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Css::Snippets');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(1) {
    my $self = shift;

    my $sty = Quiq::Css::Snippets->new(
        page => q~
            body {
                font-family: sans-serif;
                font-size: 11pt;
            }
        ~,
        menubar => q~
            #menubar {
                font-size: 14pt;
            }
            #menubar li {
                padding-left: 18px;
                padding-right: 18px;
            }
        ~
    );

    my $cssCode = $sty->snippets('page','menubar');
    $self->isText($cssCode,q~
        body {
            font-family: sans-serif;
            font-size: 11pt;
        }
        #menubar {
            font-size: 14pt;
        }
        #menubar li {
            padding-left: 18px;
            padding-right: 18px;
        }
    ~);

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Css::Snippets::Test->runTests;

# eof
