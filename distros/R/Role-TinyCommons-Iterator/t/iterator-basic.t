#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use Local::Array::Iterator::Basic;

my $iter = Local::Array::Iterator::Basic->new(1,2,3);

my @items; while ($iter->has_next_item) { push @items, $iter->get_next_item }
is_deeply(\@items, [1,2,3]);
ok(!$iter->has_next_item);
dies_ok { $iter->get_next_item };

done_testing;
