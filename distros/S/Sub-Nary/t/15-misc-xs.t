#!perl -T

use strict;
use warnings;

use Test::More tests => 12;

use Sub::Nary;

my @scalops = Sub::Nary::scalops();
my $nbr     = Sub::Nary::scalops();

is($nbr, scalar @scalops, 'scalops return values in list/scalar context are consistent');

*normalize = *Sub::Nary::normalize{CODE};

is_deeply(normalize(1),  { 1 => 1 }, 'normalize const');
is_deeply(normalize({}), { 0 => 1 }, 'normalize empty-ref');

*scale = *Sub::Nary::scale{CODE};

is_deeply(scale(1, {}), { 0 => 1 }, 'scale const, empty-ref');

*add = *Sub::Nary::add{CODE};

is_deeply(add('list'),             { list => 1 }, 'add list');
is_deeply(add(1, 'list'),          { list => 1 }, 'add const, list');
is_deeply(add({ }, 'list'),        { list => 1 }, 'add empty-ref, list');
is_deeply(add({ 1 => 1 }, 'list'), { list => 1 }, 'add ref, list');
is_deeply(add({ 1 => 1 }, 1),      { 1 => 2 }, 'add ref, prev-const');

*cumulate = *Sub::Nary::cumulate{CODE};

is_deeply(cumulate('list', 1, 1), 'list', 'cumulate const, non-zero, non-zero');
is_deeply(cumulate({ 1 => 1 }, 1, 0), { 1 => 1 }, 'cumulate ref, non-zero, zero');
is_deeply(cumulate({ }, 1, 1), undef, 'cumulate empty-ref, non-zero, non-zero');
