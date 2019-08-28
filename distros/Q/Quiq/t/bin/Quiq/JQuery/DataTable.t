#!/usr/bin/env perl

package Quiq::JQuery::DataTable::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Html::Tag;
use Quiq::Hash;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::JQuery::DataTable');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::JQuery::DataTable->new;
    $self->is(ref($e),'Quiq::JQuery::DataTable');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_unitTest_2 : Test(4) {
    my $self = shift;

    my $h = Quiq::Html::Tag->new;

    my $e = Quiq::JQuery::DataTable->new(
        id => 'myTable',
        columns => [
            { # A
                title => 'A',
            }, { # B
                title => 'B',
            },
        ],
        rows => [
            Quiq::Hash->new(
                a => 1,
                b => 1,
            ),
            Quiq::Hash->new(
                a => 2,
                b => 2,
            ),
        ],
        rowCallback => sub {
            my ($row,$i) = @_;
            return (undef,$row->a,$row->b);
        },
        instantiate => 1,
    );

    my $html = $e->html($h);
    $self->like($html,qr|<table class="compac.*id="myTable" cellspacing="0">|);
    $self->like($html,qr|\Q<th>A</th>|);
    $self->like($html,qr|\Q<td>1</td>|);
    $self->like($html,qr|\QjQuery('#myTable').DataTable(|);
}

# -----------------------------------------------------------------------------

package main;
Quiq::JQuery::DataTable::Test->runTests;

# eof
