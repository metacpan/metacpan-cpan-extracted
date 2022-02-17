#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Intervals';

my $obj = new_ok 'Music::Intervals';

is_deeply $obj->by_name('C'), { ratio => '1/1', name => 'unison, perfect prime, tonic' }, 'by_name';
is_deeply $obj->by_name('c'), undef, 'undef by_name';

is_deeply $obj->by_ratio('27/25'),
    { symbol => 'Db', name => 'large limma, BP small semitone (minor second), alternate Renaissance half-step' },
    'by_ratio';

is_deeply [sort keys %{ $obj->by_description('limma') }], [qw(Db Mc enlc pm2)], 'by_description';

$obj = new_ok 'Music::Intervals' => [
    notes => [qw( C E G )],
];

is_deeply [ sort keys %{ $obj->natural_frequencies } ], [qw(C E G)], 'natural_frequencies';
is_deeply $obj->natural_intervals,
    { 'C E' => { '5/4' => '5-limit major third, 5th harmonic' },
      'C G' => { '3/2' => 'perfect fifth' },
      'E G' => { '6/5' => '5-limit minor third' } },
    'natural_intervals';
is sprintf('%.3f', $obj->natural_cents->{'C E'}), '386.314', 'natural_cents C E';
is sprintf('%.3f', $obj->natural_cents->{'C G'}), '701.955', 'natural_cents C G';
is sprintf('%.3f', $obj->natural_cents->{'E G'}), '315.641', 'natural_cents E G';
is_deeply $obj->natural_prime_factors,
    {
        'C E' => { '5/4' => '(5) / (2*2)' },
        'C G' => { '3/2' => '(3) / (2)' },
        'E G' => { '6/5' => '(2*3) / (5)' } },
    'natural_prime_factors';
is sprintf('%.3f', $obj->eq_tempered_frequencies->{C}), '261.626', 'eq_tempered_frequencies C';
is sprintf('%.3f', $obj->eq_tempered_frequencies->{E}), '329.628', 'eq_tempered_frequencies E';
is sprintf('%.3f', $obj->eq_tempered_frequencies->{G}), '391.995', 'eq_tempered_frequencies G';
is sprintf('%.3f', $obj->eq_tempered_intervals->{'C E'}), '1.260', 'eq_tempered_intervals C E';
is sprintf('%.3f', $obj->eq_tempered_intervals->{'C G'}), '1.498', 'eq_tempered_intervals C G';
is sprintf('%.3f', $obj->eq_tempered_intervals->{'E G'}), '1.189', 'eq_tempered_intervals E G';
is_deeply $obj->eq_tempered_cents,
    { 'C G' => '700', 'C E' => '400', 'E G' => '300' },
    'eq_tempered_cents';
is_deeply $obj->integer_notation, { 'G' => '67', 'E' => '64', 'C' => '60' }, 'integer_notation';

my %got = $obj->dyads([qw(C E)]);
is $got{'C E'}{natural}, '5/4', 'dyads';

%got = $obj->dyads([qw(C E G)]);
is $got{'C E'}{natural}, '5/4', 'dyads';
is $got{'C G'}{natural}, '3/2', 'dyads';
is $got{'E G'}{natural}, '6/5', 'dyads';

my $got = $obj->ratio_factorize('6/15');
is $got, '(2*3) / (3*5)', 'ratio_factorize';

$obj = new_ok 'Music::Intervals' => [
    size => 2,
    notes => [qw( C C' )],
];

is_deeply $obj->natural_intervals,
    {
        "C C'" => { '2/1' => 'octave' } },
    'octave';

$obj = new_ok 'Music::Intervals' => [
    notes => ['C'],
    size  => 1,
];
lives_ok { $obj->natural_frequencies } 'natural_frequencies';
lives_ok { $obj->natural_intervals } 'natural_intervals';
lives_ok { $obj->natural_cents } 'natural_cents';
lives_ok { $obj->natural_prime_factors } 'natural_prime_factors';
lives_ok { $obj->eq_tempered_frequencies } 'eq_tempered_frequencies';
lives_ok { $obj->eq_tempered_intervals } 'eq_tempered_intervals';
lives_ok { $obj->eq_tempered_cents } 'eq_tempered_cents';
lives_ok { $obj->integer_notation } 'integer_notation';

done_testing();
