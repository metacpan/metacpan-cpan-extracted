#!/usr/bin/env perl

package Quiq::Html::Verbatim::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Verbatim');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new('html5');

    my $html = Quiq::Html::Verbatim->html($h,
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
Quiq::Html::Verbatim::Test->runTests;

# eof
