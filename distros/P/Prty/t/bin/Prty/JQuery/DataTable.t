#!/usr/bin/env perl

package Prty::JQuery::DataTable::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::JQuery::DataTable');
}

# -----------------------------------------------------------------------------

sub test_unitTest_1 : Test(2) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::JQuery::DataTable->new;
    $self->is(ref($e),'Prty::JQuery::DataTable');

    my $html = $e->html($h);
    $self->is($html,'');
}

sub test_unitTest_2 : Test(4) {
    my $self = shift;

    my $h = Prty::Html::Tag->new;

    my $e = Prty::JQuery::DataTable->new(
        id=>'myTable',
        columns=>[
            { # A
                title=>'A',
            }, { # B
                title=>'B',
            },
        ],
        rows=>[
            Prty::Hash->new(
                a=>1,
                b=>1,
            ),
            Prty::Hash->new(
                a=>2,
                b=>2,
            ),
        ],
        rowCallback=>sub {
            my ($row,$i) = @_;
            return (undef,$row->a,$row->b);
        },
        instantiate=>1,
    );

    my $html = $e->html($h);
    # warn "\n[$html]\n";
    $self->like($html,qr|\Q<table id="myTable" cellspacing="0">|);
    $self->like($html,qr|\Q<th>A</th>|);
    $self->like($html,qr|\Q<td>1</td>|);
    $self->like($html,qr|\QjQuery('#myTable').DataTable(|);
}

# -----------------------------------------------------------------------------

package main;
Prty::JQuery::DataTable::Test->runTests;

# eof
