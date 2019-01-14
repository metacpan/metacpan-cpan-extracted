#!/usr/bin/env perl

package Quiq::ColumnFormat::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::ColumnFormat');
}

# -----------------------------------------------------------------------------

my $Table = << '__EOT__';
Berlin   |891.70|3421829
Hamburg  |755.21|1746342
München  |370.71|1407836
Rellingen| 13.18|  13691
__EOT__

sub test_asFixedWidthString : Test(1) {
    my $self = shift;

    my $data = [
        ['Berlin',891.7,3421829,],
        ['Hamburg',755.21,1746342],
        ['München',370.71,1407836],
        ['Rellingen',13.18,13691],
    ];
    my $fmtA = [
        Quiq::ColumnFormat->new('s',9,0,0,0),
        Quiq::ColumnFormat->new('f',6,2,0,0),
        Quiq::ColumnFormat->new('d',7,0,0,0),
    ];

    my $str;
    for (my $i = 0; $i < @$data; $i++) {
        for (my $j = 0; $j < 3; $j++) {
            if ($j) {
                $str .= '|';
            }
            $str .= $fmtA->[$j]->asFixedWidthString($data->[$i][$j]);
        }
        $str .= "\n";
    }

    $self->is($str,$Table);
}

# -----------------------------------------------------------------------------

package main;
Quiq::ColumnFormat::Test->runTests;

# eof
