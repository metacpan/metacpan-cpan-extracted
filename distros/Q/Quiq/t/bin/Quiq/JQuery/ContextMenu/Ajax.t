#!/usr/bin/env perl

package Quiq::JQuery::ContextMenu::Ajax::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::ContextMenu::Ajax');
}

# -----------------------------------------------------------------------------

sub test_js : Test(4) {
    my $self = shift;

    my $obj = Quiq::JQuery::ContextMenu::Ajax->new(
        selector => '.context',
    );
    $self->is(ref($obj),'Quiq::JQuery::ContextMenu::Ajax');

    my $js = $obj->js;
    # warn $js,"\n";
    $self->like($js,qr/selector:/);
    $self->unlike($js,qr/trigger:/);
    $self->like($js,qr/build:/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::ContextMenu::Ajax::Test->runTests;

# eof
