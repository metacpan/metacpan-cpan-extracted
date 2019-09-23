#!/usr/bin/env perl

package Quiq::Html::Table::Base::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

use Quiq::Html::Tag;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Table::Base');
}

# -----------------------------------------------------------------------------

our $Table1 = <<'__HTML__';
<table border="1" cellspacing="0"></table>
__HTML__

sub test_unitTest : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $html = Quiq::Html::Table::Base->html($h);
    $self->is($html,'');

    $html = Quiq::Html::Table::Base->html($h,'');
    $self->is($html,$Table1);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Table::Base::Test->runTests;

# eof
