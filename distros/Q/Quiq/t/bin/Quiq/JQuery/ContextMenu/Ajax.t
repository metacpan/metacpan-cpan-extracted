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

sub test_js : Test(5) {
    my $self = shift;

    my $obj = Quiq::JQuery::ContextMenu::Ajax->new(
        className => 'contextMenu',
        selector => '.popup',
        trigger => 'left',
    );
    $self->is(ref($obj),'Quiq::JQuery::ContextMenu::Ajax');

    my $js = $obj->js;
    # warn $js,"\n";
    $self->like($js,qr/className:/);
    $self->like($js,qr/build:/);
    $self->like($js,qr/selector:/);
    $self->like($js,qr/trigger:/);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::ContextMenu::Ajax::Test->runTests;

# eof
