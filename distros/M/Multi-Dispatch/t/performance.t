#! /usr/bin/env perl

use 5.022;

use warnings;
use experimentals;
use Test::More;

if (!-t *STDOUT) {
    plan skip_all => 'Skipping performance tests under perltest';
    exit();
}

{ use Time::HiRes 'time'; my $start; BEGIN { $start = time(); } diag 'startup: ', time() - $start; }

use Multi::Dispatch;

multi quicksort_m ()              { () }
multi quicksort_m ($single)       { $single }
multi quicksort_m ($pivot, @tail) { quicksort_m(grep {$_ <  $pivot} @tail),
                                        $pivot,
                                        quicksort_m(grep {$_ >= $pivot} @tail)
                                      }

sub quicksort_s ($pivot = (return), @tail) {
    !@tail ? $pivot
           : ( quicksort_s(grep {$_ <  $pivot} @tail),
               $pivot,
               quicksort_s(grep {$_ >= $pivot} @tail)
             )
}


multi merge_m ([@x], []) { @x }
multi merge_m ([], [@y]) { @y }
multi merge_m ([$x, @x], [$y, @y]) {
    $x < $y ? ( $x, merge_m \@x, [$y, @y] )
            : ( $y, merge_m [$x, @x], \@y )
}

multi mergesort_m ()        {}
multi mergesort_m ($single) { $single }
multi mergesort_m (@list)   {
    merge_m
        [mergesort_m  @list[0..@list/2-1]    ],
        [mergesort_m  @list[@list/2..$#list] ]
}

sub merge_s ($list1, $list2) {
      !@{$list2}                ?  @{$list1}
    : !@{$list1}                ?  @{$list2}
    : $list1->[0] < $list2->[0] ?  ( $list1->[0], merge_m [$list1->@[1..$#{$list1}]], $list2 )
    :                              ( $list2->[0], merge_m $list1, [$list2->@[1..$#{$list2}]] )
}

sub mergesort_s (@list) {
    @list < 2  ?  @list
               :  merge_s [mergesort_s( @list[0..@list/2-1]    )],
                          [mergesort_s( @list[@list/2..$#list] )]
}

use Benchmark qw( cmpthese );
use List::Util 'shuffle';

plan tests => 4;

is_deeply [quicksort_s(shuffle 1..100)], [1..100] => 'quicksort_s';
is_deeply [quicksort_m(shuffle 1..100)], [1..100] => 'quicksort_m';
is_deeply [mergesort_s(shuffle 1..100)], [1..100] => 'mergesort_s';
is_deeply [mergesort_m(shuffle 1..100)], [1..100] => 'mergesort_m';

diag 'Benchmarking...';
{
    local *STDOUT;
    open *STDOUT, '>', \my $results;

    my @list = map { int rand 100 } 1..100;
    cmpthese -1, {
        qs_m => sub { my @res = quicksort_m(@list) },
        qs_s => sub { my @res = quicksort_s(@list) },
        ms_m => sub { my @res = mergesort_m(@list) },
        ms_s => sub { my @res = mergesort_s(@list) },
    };

    diag $results;
}

done_testing();
