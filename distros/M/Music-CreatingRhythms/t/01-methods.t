#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use List::Util qw(sum0);

my $module = 'Music::CreatingRhythms';

use_ok $module;

subtest defaults => sub {
    my $mcr = new_ok $module => [
        verbose => 1,
    ];

    is $mcr->verbose, 1, 'verbose';
};

subtest b2int => sub {
    my $mcr = new_ok $module;

    my $expect = [[1,2,3]];
    my $got = $mcr->b2int([[1,1,0,1,0,0]]);
    is_deeply $got, $expect, 'b2int';

    $expect = [[1],[2],[3]];
    $got = $mcr->b2int([[1],[1,0],[1,0,0]]);
    is_deeply $got, $expect, 'b2int';
};

subtest cfcv => sub {
    my $mcr = new_ok $module;

    # sqrt(2)
    my $expect = [3,2];
    my $got = $mcr->cfcv(1, 2);
    is_deeply $got, $expect, 'cfcv';

    $expect = [7,5];
    $got = $mcr->cfcv(1, 2, 2);
    is_deeply $got, $expect, 'cfcv';

    $expect = [17,12];
    $got = $mcr->cfcv(1, 2, 2, 2);
    is_deeply $got, $expect, 'cfcv';

    # sqrt(3)
    $expect = [5,3];
    $got = $mcr->cfcv(1, 1, 2);
    is_deeply $got, $expect, 'cfcv';

    $expect = [19,11];
    $got = $mcr->cfcv(1, 1, 2, 1, 2);
    is_deeply $got, $expect, 'cfcv';
};

subtest cfsqrt => sub {
    my $mcr = new_ok $module;

    my $expect = [1,2];
    my $got = $mcr->cfsqrt(2);
    is_deeply $got, $expect, 'cfsqrt';

    $expect = [1,2,2];
    $got = $mcr->cfsqrt(2, 3);
    is_deeply $got, $expect, 'cfsqrt';

    $expect = [1,1,2];
    $got = $mcr->cfsqrt(3);
    is_deeply $got, $expect, 'cfsqrt';

    $expect = [1,1,2,1];
    $got = $mcr->cfsqrt(3, 4);
    is_deeply $got, $expect, 'cfsqrt';

    $expect = [1,1,2,1,2];
    $got = $mcr->cfsqrt(3, 5);
    is_deeply $got, $expect, 'cfsqrt';
};

subtest chsequl => sub {
    my $mcr = new_ok $module;

    my $expect = [0];
    my $got = $mcr->chsequl('l', 1, 0);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1];
    $got = $mcr->chsequl('u', 1, 0);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,1];
    $got = $mcr->chsequl('l', 1, 1);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,0];
    $got = $mcr->chsequl('u', 1, 1);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,0,1];
    $got = $mcr->chsequl('l', 1, 2);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,0,0];
    $got = $mcr->chsequl('u', 1, 2);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,1];
    $got = $mcr->chsequl('l', 2, 0);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,1];
    $got = $mcr->chsequl('u', 2, 0);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,1,1];
    $got = $mcr->chsequl('l', 2, 1);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,1,0];
    $got = $mcr->chsequl('u', 2, 1);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,1,0,1];
    $got = $mcr->chsequl('l', 2, 2);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,0,1,0];
    $got = $mcr->chsequl('u', 2, 2);
    is_deeply $got, $expect, 'chsequl';

    $expect = [0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,1];
    $got = $mcr->chsequl('l', 11, 5);
    is_deeply $got, $expect, 'chsequl';

    $expect = [1,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0];
    $got = $mcr->chsequl('u', 11, 5);
    is_deeply $got, $expect, 'chsequl';
};

subtest comp => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->comp(1);
    is_deeply $got, $expect, 'comp';

    $expect = [[1,1],[2]];
    $got = $mcr->comp(2);
    is_deeply $got, $expect, 'comp';

    $expect = [[1,1,1],[1,2],[2,1],[3]];
    $got = $mcr->comp(3);
    is_deeply $got, $expect, 'comp';

    $expect = [[1,1,1,1],[1,1,2],[1,2,1],[1,3],[2,1,1],[2,2],[3,1],[4]];
    $got = $mcr->comp(4);
    is_deeply $got, $expect, 'comp';
};

subtest compa => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->compa(1, 1);
    is_deeply $got, $expect, 'compa';

   $expect = [];
   $got = $mcr->compa(1, 2);
   is_deeply $got, $expect, 'compa';

    $expect = [[2]];
    $got = $mcr->compa(2, 2);
    is_deeply $got, $expect, 'compa';

    $expect = [[1,1,1]];
    $got = $mcr->compa(3, 1);
    is_deeply $got, $expect, 'compa';

    $expect = [[1,1,1,1]];
    $got = $mcr->compa(4, 1);
    is_deeply $got, $expect, 'compa';

    $expect = [[1,1,1,1],[1,1,2],[1,2,1],[2,1,1],[2,2]];
    $got = $mcr->compa(4, 1,2);
    is_deeply $got, $expect, 'compa';

    $expect = [[1,1,1,1],[1,1,2],[1,2,1],[1,3],[2,1,1],[2,2],[3,1]];
    $got = $mcr->compa(4, 1,2,3);
    is_deeply $got, $expect, 'compa';
};

subtest compam => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->compam(1, 1, 1);
    is_deeply $got, $expect, 'compam';

    $expect = [];
    $got = $mcr->compam(1, 2, 1);
    is_deeply $got, $expect, 'compam';

    $expect = [[1,1]];
    $got = $mcr->compam(2, 2, 1);
    is_deeply $got, $expect, 'compam';

    $expect = [[1,1,1]];
    $got = $mcr->compam(3, 3, 1);
    is_deeply $got, $expect, 'compam';

    $expect = [[1,1,1,1]];
    $got = $mcr->compam(4, 4, 1);
    is_deeply $got, $expect, 'compam';

    $expect = [[1,1,2],[1,2,1],[2,1,1]];
    $got = $mcr->compam(4, 3, 1,2);
    is_deeply $got, $expect, 'compam';

    $expect = [[1,3],[2,2],[3,1]];
    $got = $mcr->compam(4, 2, 1,2,3);
    is_deeply $got, $expect, 'compam';
};

subtest compm => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->compm(1, 1);
    is_deeply $got, $expect, 'compm';

    $expect = [];
    $got = $mcr->compm(1, 2);
    is_deeply $got, $expect, 'compm';

    $expect = [[1,1]];
    $got = $mcr->compm(2, 2);
    is_deeply $got, $expect, 'compm';

    $expect = [[1,2],[2,1]];
    $got = $mcr->compm(3, 2);
    is_deeply $got, $expect, 'compm';

    $expect = [[1,3],[2,2],[3,1]];
    $got = $mcr->compm(4, 2);
    is_deeply $got, $expect, 'compm';

    $expect = [[1,4],[2,3],[3,2],[4,1]];
    $got = $mcr->compm(5, 2);
    is_deeply $got, $expect, 'compm';

    $expect = [[1,5],[2,4],[3,3],[4,2],[5,1]];
    $got = $mcr->compm(6, 2);
    is_deeply $got, $expect, 'compm';
};

subtest compmrnd => sub {
    my $mcr = new_ok $module;

    my $expect = 0;
    my $got = $mcr->compmrnd(0, 0);
    is sum0(@$got), $expect, 'compmrnd';

    $expect = 1;
    $got = $mcr->compmrnd(1, 1);
    is sum0(@$got), $expect, 'compmrnd';

    $expect = 16;
    $got = $mcr->compmrnd(16, 4);
    is sum0(@$got), $expect, 'compmrnd';
};

subtest comprnd => sub {
    my $mcr = new_ok $module;

    my $expect = 0;
    my $got = $mcr->comprnd(0);
    is sum0(@$got), $expect, 'comprnd';

    $expect = 1;
    $got = $mcr->comprnd(1);
    is sum0(@$got), $expect, 'comprnd';

    $expect = 16;
    $got = $mcr->comprnd(16);
    is sum0(@$got), $expect, 'comprnd';
};

subtest count_ones => sub {
    my $mcr = new_ok $module;

    my $expect = 0;
    my $got = $mcr->count_ones(0);
    is $got, $expect, 'count_ones';

    $expect = 0;
    $got = $mcr->count_ones([0]);
    is $got, $expect, 'count_ones';

    $expect = 1;
    $got = $mcr->count_ones(1);
    is $got, $expect, 'count_ones';

    $expect = 1;
    $got = $mcr->count_ones([1]);
    is $got, $expect, 'count_ones';

    $expect = 1;
    $got = $mcr->count_ones('010');
    is $got, $expect, 'count_ones';

    $expect = 1;
    $got = $mcr->count_ones([0,1,0]);
    is $got, $expect, 'count_ones';
};

subtest count_zeros => sub {
    my $mcr = new_ok $module;

    my $expect = 1;
    my $got = $mcr->count_zeros(0);
    is $got, $expect, 'count_zeros';

    $expect = 1;
    $got = $mcr->count_zeros([0]);
    is $got, $expect, 'count_zeros';

    $expect = 0;
    $got = $mcr->count_zeros(1);
    is $got, $expect, 'count_zeros';

    $expect = 0;
    $got = $mcr->count_zeros([1]);
    is $got, $expect, 'count_zeros';

    $expect = 2;
    $got = $mcr->count_zeros('010');
    is $got, $expect, 'count_zeros';

    $expect = 2;
    $got = $mcr->count_zeros([0,1,0]);
    is $got, $expect, 'count_zeros';
};

subtest de_bruijn => sub {
    my $mcr = new_ok $module;

    my $expect = [0];
    my $got = $mcr->de_bruijn(0);
    is_deeply $got, $expect, 'de_bruijn';

    $expect = [qw(1 0)];
    $got = $mcr->de_bruijn(1);
    is_deeply $got, $expect, 'de_bruijn';

    $expect = [qw(1 1 0 0)];
    $got = $mcr->de_bruijn(2);
    is_deeply $got, $expect, 'de_bruijn';

    $expect = [qw(1 1 1 0 1 0 0 0)];
    $got = $mcr->de_bruijn(3);
    is_deeply $got, $expect, 'de_bruijn';
};

subtest euclid => sub {
    my $mcr = new_ok $module;

    my $expect = [1];
    my $got = $mcr->euclid(1, 1);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,0];
    $got = $mcr->euclid(1, 2);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,0,0];
    $got = $mcr->euclid(1, 3);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,0,0,0];
    $got = $mcr->euclid(1, 4);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,0,1,0];
    $got = $mcr->euclid(2, 4);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,1,0,1];
    $got = $mcr->euclid(3, 4);
    is_deeply $got, $expect, 'euclid';

    $expect = [1,1,1,1];
    $got = $mcr->euclid(4, 4);
    is_deeply $got, $expect, 'euclid';
};

subtest int2b => sub {
    my $mcr = new_ok $module;

    my $expect = [[1,1,0,1,0,0]];
    my $got = $mcr->int2b([[1,2,3]]);
    is_deeply $got, $expect, 'int2b';

    $expect = [[1],[1,0],[1,0,0]];
    $got = $mcr->int2b([[1],[2],[3]]);
    is_deeply $got, $expect, 'int2b';
};

subtest invert_at => sub {
    my $mcr = new_ok $module;

    my $parts = [qw(1 0 1 0 0)];

    my $expect = [qw(0 1 0 1 1)];
    my $got = $mcr->invert_at(0, $parts);
    is_deeply $got, $expect, 'invert_at';

    $expect = [qw(1 1 0 1 1)];
    $got = $mcr->invert_at(1, $parts);
    is_deeply $got, $expect, 'invert_at';

    $expect = [qw(1 0 0 1 1)];
    $got = $mcr->invert_at(2, $parts);
    is_deeply $got, $expect, 'invert_at';

    $expect = [qw(1 0 1 1 1)];
    $got = $mcr->invert_at(3, $parts);
    is_deeply $got, $expect, 'invert_at';

    $expect = [qw(1 0 1 0 1)];
    $got = $mcr->invert_at(4, $parts);
    is_deeply $got, $expect, 'invert_at';

    $expect = [qw(1 0 1 0 0)];
    $got = $mcr->invert_at(5, $parts);
    is_deeply $got, $expect, 'invert_at';
};

subtest neck => sub {
    my $mcr = new_ok $module;

    my $expect = [[1],[0]];
    my $got = $mcr->neck(1);
    is_deeply $got, $expect, 'neck';

    $expect = [[1,1],[1,0],[0,0]];
    $got = $mcr->neck(2);
    is_deeply $got, $expect, 'neck';

    $expect = [[1,1,1],[1,1,0],[1,0,0],[0,0,0]];
    $got = $mcr->neck(3);
    is_deeply $got, $expect, 'neck';

    $expect = [[1,1,1,1],[1,1,1,0],[1,1,0,0],[1,0,1,0],[1,0,0,0],[0,0,0,0]];
    $got = $mcr->neck(4);
    is_deeply $got, $expect, 'neck';
};

subtest necka => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->necka(1, 1);
    is_deeply $got, $expect, 'necka';

   $expect = [];
   $got = $mcr->necka(1, 2);
   is_deeply $got, $expect, 'necka';

    $expect = [[1,0]];
    $got = $mcr->necka(2, 2);
    is_deeply $got, $expect, 'necka';

    $expect = [[1,1,1]];
    $got = $mcr->necka(3, 1);
    is_deeply $got, $expect, 'necka';

    $expect = [[1,1,1,1]];
    $got = $mcr->necka(4, 1);
    is_deeply $got, $expect, 'necka';

    $expect = [[1,1,1,1],[1,1,1,0],[1,0,1,0]];
    $got = $mcr->necka(4, 1,2);
    is_deeply $got, $expect, 'necka';

    $expect = [[1,1,1,1],[1,1,1,0],[1,1,0,0],[1,0,1,0]];
    $got = $mcr->necka(4, 1,2,3);
    is_deeply $got, $expect, 'necka';
};

subtest neckam => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->neckam(1, 1, 1);
    is_deeply $got, $expect, 'neckam';

    $expect = [];
    $got = $mcr->neckam(1, 2, 1);
    is_deeply $got, $expect, 'neckam';

    $expect = [[1,1]];
    $got = $mcr->neckam(2, 2, 1);
    is_deeply $got, $expect, 'neckam';

    $expect = [[1,1,1]];
    $got = $mcr->neckam(3, 3, 1);
    is_deeply $got, $expect, 'neckam';

    $expect = [[1,1,1,1]];
    $got = $mcr->neckam(4, 4, 1);
    is_deeply $got, $expect, 'neckam';

    $expect = [[1,1,1,0]];
    $got = $mcr->neckam(4, 3, 1,2);
    is_deeply $got, $expect, 'neckam';

    $expect = [[1,1,0,0],[1,0,1,0]];
    $got = $mcr->neckam(4, 2, 1,2,3);
    is_deeply $got, $expect, 'neckam';
};


subtest neckm => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->neckm(1, 1);
    is_deeply $got, $expect, 'neckm';

    $expect = [];
    $got = $mcr->neckm(1, 2);
    is_deeply $got, $expect, 'neckm';

    $expect = [[1,1]];
    $got = $mcr->neckm(2, 2);
    is_deeply $got, $expect, 'neckm';

    $expect = [[1,1,0]];
    $got = $mcr->neckm(3, 2);
    is_deeply $got, $expect, 'neckm';

    $expect = [[1,1,0,0],[1,0,1,0]];
    $got = $mcr->neckm(4, 2);
    is_deeply $got, $expect, 'neckm';

    $expect = [[1,1,0,0,0],[1,0,1,0,0]];
    $got = $mcr->neckm(5, 2);
    is_deeply $got, $expect, 'neckm';

    $expect = [[1,1,0,0,0,0],[1,0,1,0,0,0],[1,0,0,1,0,0]];
    $got = $mcr->neckm(6, 2);
    is_deeply $got, $expect, 'neckm';
};

subtest part => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->part(1);
    is_deeply $got, $expect, 'part';

    $expect = [[1,1],[2]];
    $got = $mcr->part(2);
    is_deeply $got, $expect, 'part';

    $expect = [[1,1,1],[1,2],[3]];
    $got = $mcr->part(3);
    is_deeply $got, $expect, 'part';

    $expect = [[1,1,1,1],[1,1,2],[2,2],[1,3],[4]];
    $got = $mcr->part(4);
    is_deeply $got, $expect, 'part';
};

subtest parta => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->parta(1, 1);
    is_deeply $got, $expect, 'parta';

    $expect = [];
    $got = $mcr->parta(1, 2);
    is_deeply $got, $expect, 'parta';

    $expect = [[2]];
    $got = $mcr->parta(2, 2);
    is_deeply $got, $expect, 'parta';

    $expect = [[1,1,1]];
    $got = $mcr->parta(3, 1);
    is_deeply $got, $expect, 'parta';

    $expect = [[1,1,1,1]];
    $got = $mcr->parta(4, 1);
    is_deeply $got, $expect, 'parta';

    $expect = [[1,1,1,1],[1,1,2],[2,2]];
    $got = $mcr->parta(4, 1,2);
    is_deeply $got, $expect, 'parta';

    $expect = [[1,1,1,1],[1,1,2],[2,2],[1,3]];
    $got = $mcr->parta(4, 1,2,3);
    is_deeply $got, $expect, 'parta';
};

subtest partam => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->partam(1, 1, 1);
    is_deeply $got, $expect, 'partam';

    $expect = [];
    $got = $mcr->partam(1, 2, 1);
    is_deeply $got, $expect, 'partam';

    $expect = [[1,1]];
    $got = $mcr->partam(2, 2, 1);
    is_deeply $got, $expect, 'partam';

    $expect = [[1,1,1]];
    $got = $mcr->partam(3, 3, 1);
    is_deeply $got, $expect, 'partam';

    $expect = [[1,1,1,1]];
    $got = $mcr->partam(4, 4, 1);
    is_deeply $got, $expect, 'partam';

    $expect = [[1,1,2]];
    $got = $mcr->partam(4, 3, 1,2);
    is_deeply $got, $expect, 'partam';

    $expect = [[1,3],[2,2]];
    $got = $mcr->partam(4, 2, 1,2,3);
    is_deeply $got, $expect, 'partam';
};

subtest partm => sub {
    my $mcr = new_ok $module;

    my $expect = [[1]];
    my $got = $mcr->partm(1, 1);
    is_deeply $got, $expect, 'partm';

    $expect = [];
    $got = $mcr->partm(1, 2);
    is_deeply $got, $expect, 'partm';

    $expect = [[1,1]];
    $got = $mcr->partm(2, 2);
    is_deeply $got, $expect, 'partm';

    $expect = [[1,2]];
    $got = $mcr->partm(3, 2);
    is_deeply $got, $expect, 'partm';

    $expect = [[1,3],[2,2]];
    $got = $mcr->partm(4, 2);
    is_deeply $got, $expect, 'partm';

    $expect = [[1,4],[2,3]];
    $got = $mcr->partm(5, 2);
    is_deeply $got, $expect, 'partm';

    $expect = [[1,5],[2,4],[3,3]];
    $got = $mcr->partm(6, 2);
    is_deeply $got, $expect, 'partm';
};

subtest permi => sub {
    my $mcr = new_ok $module;

    my $parts = [qw(1 0 1)];

    my $expect = [[1,0,1],[1,1,0],[0,1,1],[0,1,1],[1,1,0],[1,0,1]];
    my $got = $mcr->permi($parts);
    is_deeply $got, $expect, 'permi';
};

subtest pfold => sub {
    my $mcr = new_ok $module;

    my $expect = [1];
    my $got = $mcr->pfold(1, 1, 1);
    is_deeply $got, $expect, 'pfold';

    $expect = [1,1];
    $got = $mcr->pfold(2, 1, 1);
    is_deeply $got, $expect, 'pfold';

    $expect = [1,1,0];
    $got = $mcr->pfold(3, 1, 1);
    is_deeply $got, $expect, 'pfold';

    $expect = [1,1,0,1];
    $got = $mcr->pfold(4, 1, 1);
    is_deeply $got, $expect, 'pfold';

    $expect = [0,0,1,0,0,1,1,0,0,0,1,1,0,1,1];
    $got = $mcr->pfold(15, 4, 0);
    is_deeply $got, $expect, 'pfold';

    $expect = [1,0,0,0,1,1,0,0,1,0,0,1,1,1,0];
    $got = $mcr->pfold(15, 4, 1);
    is_deeply $got, $expect, 'pfold';
};

subtest reverse_at => sub {
    my $mcr = new_ok $module;

    my $parts = [qw(1 0 1 0 0)];

    my $expect = [qw(0 0 1 0 1)];
    my $got = $mcr->reverse_at(0, $parts);
    is_deeply $got, $expect, 'reverse_at';

    $expect = [qw(1 0 0 1 0)];
    $got = $mcr->reverse_at(1, $parts);
    is_deeply $got, $expect, 'reverse_at';

    $expect = [qw(1 0 0 0 1)];
    $got = $mcr->reverse_at(2, $parts);
    is_deeply $got, $expect, 'reverse_at';

    $expect = [qw(1 0 1 0 0)];
    $got = $mcr->reverse_at(3, $parts);
    is_deeply $got, $expect, 'reverse_at';

    $expect = [qw(1 0 1 0 0)];
    $got = $mcr->reverse_at(4, $parts);
    is_deeply $got, $expect, 'reverse_at';
};

subtest rotate_n => sub {
    my $mcr = new_ok $module;

    my $parts = [qw(1 0 1 0 0)];

    my $expect = [qw(1 0 1 0 0)];
    my $got = $mcr->rotate_n(0, $parts);
    is_deeply $got, $expect, 'rotate_n';

    $expect = [qw(0 1 0 1 0)];
    $got = $mcr->rotate_n(1, $parts);
    is_deeply $got, $expect, 'rotate_n';

    $expect = [qw(0 0 1 0 1)];
    $got = $mcr->rotate_n(2, $parts);
    is_deeply $got, $expect, 'rotate_n';

    $expect = [qw(1 0 0 1 0)];
    $got = $mcr->rotate_n(3, $parts);
    is_deeply $got, $expect, 'rotate_n';

    $expect = [qw(0 1 0 0 1)];
    $got = $mcr->rotate_n(4, $parts);
    is_deeply $got, $expect, 'rotate_n';

    $expect = [qw(1 0 1 0 0)];
    $got = $mcr->rotate_n(5, $parts);
    is_deeply $got, $expect, 'rotate_n';
};

done_testing();
