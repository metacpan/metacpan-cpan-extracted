#!/usr/bin/env perl

package Prty::Html::Table::Base::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Html::Table::Base');
}

# -----------------------------------------------------------------------------

our $Table1 = <<'__HTML__';
<table border="1" cellspacing="0"></table>
__HTML__

sub test_unitTest : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $html = Prty::Html::Table::Base->html($h);
    $self->is($html,'');

    $html = Prty::Html::Table::Base->html($h,'');
    $self->is($html,$Table1);
}

# -----------------------------------------------------------------------------

package main;
Prty::Html::Table::Base::Test->runTests;

# eof
