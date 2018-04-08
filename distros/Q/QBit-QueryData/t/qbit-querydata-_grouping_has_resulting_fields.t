#!/usr/bin/perl

use Test::More;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $DATA = [
    {id => 1, caption => 'caption 1', user => {name => 'name 1'}, num => 10},
    {id => 2, caption => 'caption 2', user => {name => 'name 2'}, num => 20},
];

my $TESTS = [
    {
        name     => 'without grouping and distinct',
        fields   => [qw(id caption user)],
        expected => FALSE,
    },
    {
        name     => 'without grouping, with distinct',
        fields   => [qw(id caption user)],
        distinct => TRUE,
        expected => FALSE,
    },
    {
        name     => 'with grouping, without distinct',
        fields   => {caption => '', sum_num => {SUM => ['num']}},
        group_by => ['caption'],
        expected => TRUE,
    },
    {
        name     => 'with grouping, with distinct',
        fields   => {caption => '', sum_num => {SUM => ['num']}},
        group_by => ['caption'],
        distinct => TRUE,
        expected => TRUE,
    },
    {
        name     => 'with grouping, with distinct on field',
        fields   => {caption => {DISTINCT => ['caption']}, sum_num => {SUM => ['num']}},
        group_by => ['caption'],
        expected => TRUE,
    },
    {
        name     => 'with grouping, with distinct (result has not fields from grouping)',
        fields   => {sum_num => {SUM => ['num']}},
        group_by => ['caption'],
        distinct => TRUE,
        expected => FALSE,
    },
    {
        name     => 'with grouping, with distinct on field (result has not fields from grouping)',
        fields   => {id => {DISTINCT => ['id']}, sum_num => {SUM => ['num']}},
        group_by => ['caption'],
        expected => FALSE,
    },
    {
        name     => 'with grouping, with distinct (result has not fields from grouping - complex field)',
        fields   => {sum_num => {SUM => ['num']}},
        group_by => ['user.name'],
        distinct => TRUE,
        expected => FALSE,
    },
    {
        name     => 'with grouping, with distinct on field (result has not fields from grouping - complex field)',
        fields   => {id => {DISTINCT => ['id']}, sum_num => {SUM => ['num']}},
        group_by => ['user.name'],
        expected => FALSE,
    },
    {
        name     => 'with grouping, with distinct (complex field)',
        fields   => {user_name => 'user.name', sum_num => {SUM => ['num']}},
        group_by => ['user.name'],
        distinct => TRUE,
        expected => TRUE,
    },
    {
        name     => 'with grouping, with distinct on field (complex field)',
        fields   => {user_name => {DISTINCT => ['user.name']}, sum_num => {SUM => ['num']}},
        group_by => ['user.name'],
        expected => TRUE,
    },
];

foreach my $test (@$TESTS) {
    my $q = QBit::QueryData->new(data => $DATA);

    $q->fields($test->{'fields'});

    $q->group_by(@{$test->{'group_by'}}) if exists($test->{'group_by'});
    $q->distinct($test->{'distinct'}) if exists($test->{'distinct'});

    ok($q->_grouping_has_resulting_fields eq $test->{'expected'}, $test->{'name'});
}

done_testing();
