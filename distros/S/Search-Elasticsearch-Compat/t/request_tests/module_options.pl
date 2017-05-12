#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

my ($node_id) = keys %{ $es->nodes->{nodes} };
ok $es->camel_case(1), 'Camel case on';
ok $es->nodes->{nodes}{$node_id}{transportAddress}, ' - got camel case';
ok $es->camel_case(0) == 0, ' - camel case off';
ok $es->nodes->{nodes}{$node_id}{transport_address}, ' - got underscores';

1
