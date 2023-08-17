#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark 'cmpthese';

use SQL::Abstract;
use SQL::Inserter;
use SQL::Maker;

my $sql_abstract  = SQL::Abstract->new();
my $sql_maker     = SQL::Maker->new(driver => 'mysql');
my ($data, $cols) = create_data();

print "Compare SQL::Abstract, SQL::Maker, simple_insert:\n";
cmpthese -2, {
    'Abstract cached' => sub {
        my ($stmt, @bind) = $sql_abstract->insert('data_table', data());
    },
    'Maker cached' => sub {
        my ($stmt, @bind) = $sql_maker->insert('data_table', data());
    },
    Abstract => sub {
        my $sql = SQL::Abstract->new();
        my ($stmt, @bind) = $sql->insert('data_table', data());
    },
    Maker => sub {
        my $sql = SQL::Maker->new(driver => 'mysql');
        my ($stmt, @bind) = $sql->insert('data_table', data());
    },
    simple_insert => sub {
        my ($stmt, @bind) = SQL::Inserter::simple_insert('data_table', data());
    },
};

print "\nCompare simple_insert, multi_insert_sql for single row:\n";

cmpthese -2, {
    simple_insert => sub {
        my ($stmt, @bind) = SQL::Inserter::simple_insert('data_table', data());
    },
    multi_insert_sql => sub {
        my $stmt = SQL::Inserter::multi_insert_sql('data_table', cols());
    },
};

sub create_data {
    my (@data, @cols);
    foreach (1..20) {
        my $d = {
        id   => int(rand(10000000)),
        date => \"NOW()",
        map {"data".$_ => "foo bar" x int(rand(5)+1)} 1..int(rand(20)+1)
        };
        push @data, $d;
        push @cols, [keys %$d];
    }
    return \@data, \@cols;
}

sub cols {
    return $cols->[int(rand(20))];
}

sub data {
    return $data->[int(rand(20))];
}
