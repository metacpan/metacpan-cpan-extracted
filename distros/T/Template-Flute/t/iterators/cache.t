#! perl
#
# Testing functions of cache iterator.

use strict;
use warnings;
use Test::More;

use Template::Flute::Iterator;
use Template::Flute::Iterator::Cache;

my ($cart, $iter);

$cart = [{isbn => '978-0-2016-1622-4', title => 'The Pragmatic Programmer',
          quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1},
 		];

$iter = new Template::Flute::Iterator($cart);
isa_ok($iter, 'Template::Flute::Iterator');

ok($iter->count == 2);

# isa_ok($iter->next, 'HASH');

my $record;
my $iter_cached = Template::Flute::Iterator::Cache->new(iterator => $iter);

isa_ok($iter_cached, 'Template::Flute::Iterator::Cache');

my $count = $iter_cached->count;

ok($count == 2, 'Count of cached iterator')
    || diag "Count: $count";

for my $i (1, 2) {
    $record = $iter_cached->next;
    isa_ok($record, 'HASH');
    ok($i == $iter_cached->index);
}

$record = $iter_cached->next;
ok (! defined $record);

done_testing;
