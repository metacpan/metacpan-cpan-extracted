#! /usr/bin/perl
use Test2::V0;
plan 2;

use String::Eertree;

subtest 'single char' => sub {
    plan 4;

    my $e = 'String::Eertree'->new(string => 'a');
    is $e->Last, 2, 'size';
    is $e->nodes->[0]->edge, {a => 2}, 'edge -1->a';
    is $e->nodes->[2]->link, 1, 'link a->1';
    is $e->nodes->[2]->string($e), 'a', 'string a';
};

subtest 'two chars' => sub {
    plan 7;

    my $e = 'String::Eertree'->new(string => 'aa');
    is $e->Last, 3, 'size';
    is $e->nodes->[0]->edge, {a => 2}, 'edge -1->a';
    is $e->nodes->[1]->edge, {a => 3}, 'edge 0->aa';
    is $e->nodes->[2]->string($e), 'a', 'string a';
    is $e->nodes->[2]->link, 1, 'link';
    is $e->nodes->[3]->string($e), 'aa', 'string aa';
    is $e->nodes->[3]->link, 2, 'link aa->a';
};
