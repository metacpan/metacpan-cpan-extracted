#!/usr/bin/env perl

package Quiq::Html::Resources::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Html::Resources');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Test(2) {
    my $self = shift;

    my $res = Quiq::Html::Resources->new(
        jquery => {
            js => [
                'https://code.jquery.com/jquery-latest.min.js',
            ],
        },
        datatables => {
            css => [
                'https://cdn.datatables.net/v/dt/dt-1.11.3/'.
                    'datatables.min.css',
            ],
            js => [
                'https://cdn.datatables.net/v/dt/dt-1.11.3/'.
                    'datatables.min.js',
            ],
        },
    );
    $self->is(ref($res),'Quiq::Html::Resources');

    my @arr = $res->resources('jquery','datatables');
    $self->is(scalar(@arr),3);

    return;
}

# -----------------------------------------------------------------------------

package main;
Quiq::Html::Resources::Test->runTests;

# eof
