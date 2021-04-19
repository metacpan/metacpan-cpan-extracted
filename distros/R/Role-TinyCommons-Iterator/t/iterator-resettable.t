#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::Array::Iterator::Resettable;

my $iter = Local::Array::Iterator::Resettable->new(1,2,3);

subtest "get_next_item, has_next_item, reset_iterator" => sub {
    my @items; while ($iter->has_next_item) { push @items, $iter->get_next_item }
    is_deeply(\@items, [1,2,3]);
    ok(!$iter->has_next_item);
    dies_ok { $iter->get_next_item };
    $iter->reset_iterator;
    @items = (); for (1..2) { push @items, $iter->get_next_item }
    is_deeply(\@items, [1,2]);
};

subtest "get_item_count, get_all_items" => sub {
    is_deeply([$iter->get_all_items], [1,2,3]);
    is_deeply($iter->get_item_count, 3);
    my @items2;
    $iter->each_item(sub { push @items2, $_[0]*2 });
    is_deeply(\@items2, [2,4,6]);
};

done_testing;
