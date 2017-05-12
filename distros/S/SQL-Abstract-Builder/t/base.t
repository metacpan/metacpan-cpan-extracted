#!/usr/bin/env perl

package Table1;

sub query {
    -columns => [qw(id foo bar)],
    -from => 'table1',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package Table2;

sub query {
    -columns => [qw(id baz glarch)],
    -from => 'table2',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package Table3;

sub query {
    -columns => [qw(id alfa)],
    -from => 'table3',
    (@_ == 1 ? (-where => $_[0]) : @_),
}

package main;

use v5.14;
use warnings;
use lib './lib';
use SQL::Abstract::Builder qw(query build include);
use Data::Dump qw(pp);

use Test::More tests => 1;

my @res = query {'dbi:mysql:test','root'} build {
    Table1::query -key => 'id', -limit => 100,
} include {
    Table2::query -key => 'table1_id',
} include {
    Table3::query -key => 'table1_id',
};

ok(@res);
