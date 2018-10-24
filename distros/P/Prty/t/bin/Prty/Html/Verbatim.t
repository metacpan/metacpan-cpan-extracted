#!/usr/bin/env perl

package Prty::Html::Verbatim::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Verbatim');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $h = Prty::Html::Tag->new('html5');

    my $html = Prty::Html::Verbatim->html($h,
        class => 'sdoc-code',
        id => 'cod001',
        ln => 173,
        text => 'Hello world!',
    );
    $self->like($html,qr|class="sdoc-code"|);
    $self->like($html,qr|id="cod001"|);
    $self->like($html,qr|<pre>173</pre>|);
    $self->like($html,qr|<pre>Hello world!</pre>|);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Verbatim::Test->runTests;

# eof
