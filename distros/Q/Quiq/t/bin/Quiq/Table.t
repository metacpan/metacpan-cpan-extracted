#!/usr/bin/env perl

package Quiq::Table::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Table');
}

# -----------------------------------------------------------------------------

# Ohne Kolumnennamen

sub test_unitTest_noColumns : Test(3) {
    my $self = shift;

    my @rows = (
        [1,  'A',    76.253],
        [12, 'AB',    1.7  ],
        [123,'ABC',9999    ],
    );

    # new()

    my $tab = Quiq::Table->new(3,\@rows);
    $self->is(ref($tab),'Quiq::Table');

    my @values = $tab->values(1);
    $self->isDeeply(\@values,['A','AB','ABC']);

    my $str = $tab->asText;
    my $expected = Quiq::Unindent->string(q~
        |   1 | A   |   76.253 |
        |  12 | AB  |    1.700 |
        | 123 | ABC | 9999.000 |
    ~);
    $self->is($str,$expected);
}

# Mit Kolumnennamen

sub test_unitTest_columns : Test(3) {
    my $self = shift;

    my @rows = (
        [1,  'A',    76.253],
        [12, 'AB',    1.7  ],
        [123,'ABC',9999    ],
    );

    # new()

    my $tab = Quiq::Table->new(['a','b','c'],\@rows);
    $self->is(ref($tab),'Quiq::Table');

    my @values = $tab->values('b');
    $self->isDeeply(\@values,['A','AB','ABC']);

    my $str = $tab->asText;
    my $expected = Quiq::Unindent->string(q~
        |   1 | A   |   76.253 |
        |  12 | AB  |    1.700 |
        | 123 | ABC | 9999.000 |
    ~);
    $self->is($str,$expected);
}

sub test_unitTest : Test(23) {
    my $self = shift;

    # new()

    my $tab = Quiq::Table->new([qw/a b c d/]);
    $self->is(ref($tab),'Quiq::Table');

    # columns()

    my @columns = $tab->columns;
    $self->isDeeply(\@columns,[qw/a b c d/]);

    my $columnA = $tab->columns;
    $self->isDeeply($columnA,[qw/a b c d/]);

    # pos()

    my $i = $tab->pos('a');
    $self->is($i,0);

    $i = $tab->pos('d');
    $self->is($i,3);

    eval {$tab->pos('z')};
    $self->ok($@);

    # count()

    my $count = $tab->count;
    $self->is($count,0);

    # rows()

    my @rows = $tab->rows;
    $self->isDeeply(\@rows,[]);

    my $rowA = $tab->rows;
    $self->isDeeply($rowA,[]);

    # width()

    my $width = $tab->width;
    $self->is($width,4);

    # push()

    $tab->push([1,2,3,4]);

    $self->is($tab->count,1);
    my ($row) = $tab->rows;

    my $val = $row->get('c');
    $self->is($val,3);

    eval {$row->get('z')};
    $self->ok($@);

    my @values = $row->values;
    $self->isDeeply(\@values,[1,2,3,4]);

    my $valueA = $row->values;
    $self->isDeeply($valueA,[1,2,3,4]);

    eval {$tab->push([1,2,3,4,5])}; # zu viele Werte
    $self->ok($@);

    $tab->push([5,6,7,8]);

    @values = ();
    for my $row ($tab->rows) {
        my $valueA = $row->values;
        for my $value (@$valueA) {
            push @values,$value;
        }
    }
    $self->isDeeply(\@values,[1 .. 8]);

    @values = ();
    for my $row ($tab->rows) {
        for my $value ($row->values) {
            push @values,$value;
        }
    }
    $self->isDeeply(\@values,[1 .. 8]);

    @values = ();
    for my $row ($tab->rows) {
        my $valueA = $row->values;
        for my $value (@$valueA) {
            push @values,$value;
        }
    }
    $self->isDeeply(\@values,[1 .. 8]);

    @values = ();
    $width = $tab->width;
    for my $row ($tab->rows) {
        my $valueA = $row->values;
        for (my $i = 0; $i < $width; $i++) {
            push @values,$valueA->[$i];
        }
    }
    $self->isDeeply(\@values,[1 .. 8]);

    $tab->push([1,9,10,11]);

    @values = $tab->values('a');
    $self->isDeeply(\@values,[1,5,1]);

    $valueA = $tab->values('a');
    $self->isDeeply($valueA,[1,5,1]);

    @values = $tab->values('a',-distinct=>1);
    $self->isDeeply(\@values,[1,5]);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Table::Test->runTests;

# eof
