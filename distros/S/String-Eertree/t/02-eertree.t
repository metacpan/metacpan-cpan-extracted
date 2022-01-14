#! /usr/bin/perl
use Test2::V0;
plan 31;

use String::Eertree;

my $e = 'String::Eertree'->new(string => 'eertree');

is scalar @{ $e->nodes }, 9, 'size';

is $e->nodes->[0]->edge, {e => 2, r => 4, t => 5}, 'edges from -1';

is $e->nodes->[1]->edge, {e => 3}, 'edge from 0';

is $e->nodes->[2]->edge, {}, 'no edges from e';
is $e->nodes->[2]->link, 1, 'link e->0';
is $e->nodes->[2]->pos, 0, 'pos e';
is $e->nodes->[2]->string($e), 'e', 'string e';

is $e->nodes->[3]->edge, {}, 'no edges from "ee"';
is $e->nodes->[3]->link, 2, 'link ee->e';
is $e->nodes->[3]->pos, 0, 'pos ee';
is $e->nodes->[3]->string($e), 'ee', 'string ee';

is $e->nodes->[4]->edge, {}, 'no edges from r';
is $e->nodes->[4]->link, 1, 'link r->0';
is $e->nodes->[4]->pos, 2, 'pos r';
is $e->nodes->[4]->string($e), 'r', 'string r';

is $e->nodes->[5]->edge, {r => 6}, 'edge t->rtr';
is $e->nodes->[5]->link, 1, 'link t->0';
is $e->nodes->[5]->pos, 3, 'pos t';
is $e->nodes->[5]->string($e), 't', 'string t';

is $e->nodes->[6]->edge, {e => 7}, 'edge rtr->ertre';
is $e->nodes->[6]->link, 4, 'link rtr->r';
is $e->nodes->[6]->pos, 2, 'pos rtr';
is $e->nodes->[6]->string($e), 'rtr', 'string rtr';

is $e->nodes->[7]->edge, {e => 8}, 'edge ertre->eertree';
is $e->nodes->[7]->link, 2, 'link ertre->e';
is $e->nodes->[7]->pos, 1, 'pos ertre';
is $e->nodes->[7]->string($e), 'ertre', 'string ertre';

is $e->nodes->[8]->edge, {}, 'no edges from eertree';
is $e->nodes->[8]->link, 3, 'link eertree->ee';
is $e->nodes->[8]->pos, 0, 'pos eertree';
is $e->nodes->[8]->string($e), 'eertree', 'string eertree';
