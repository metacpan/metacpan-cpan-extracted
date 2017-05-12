#!perl

use 5.010;
use strict;
use warnings;

use Sort::BySpec qw(sort_by_spec cmp_by_spec);
use Test::Exception;
use Test::More 0.98;

subtest "cmp_by_spec" => sub {
    my $cmp = cmp_by_spec(spec => [4,6,5]);
    is_deeply([sort {$cmp->($a,$b)} 1..7], [4,6,5, 1,2,3,7]);
};

subtest "sort_by_spec" => sub {
    subtest "without array (return sorter)" => sub {
        my $sorter = sort_by_spec(spec=>[4,6,5]);
        is_deeply([$sorter->(1..7)], [4,6,5, 1,2,3,7]);
    };
    subtest "wrong element -> dies" => sub {
        # XXX currently it dies when actually sorting, it should've died earlier
        dies_ok { sort_by_spec(spec=>[{}], array=>[1,2]) };
    };
    subtest "spec: regex (w/ sortsub)" => sub {
        is_deeply(
            sort_by_spec(spec=>[qr/\d/ => sub {$_[1] <=> $_[0]}],
                         array=>["a","c","b",1,2,3]),
            [3,2,1,"a","c","b"],
        );
    };
    subtest "spec: regex(w/o sortsub) + strings (tests ordering)" => sub {
        is_deeply(
            sort_by_spec(spec=>[qr//, 1,2,3], array=>[1,2,3,5,6,4]),
            [5,6,4,1,2,3],
        );
    };
    subtest "spec: code (w/ sortsub)" => sub {
        is_deeply(
            sort_by_spec(spec=>[sub {$_[0] % 2} => sub {$_[1] <=> $_[0]}],
                                array=>[1..6]),
            [5,3,1,2,4,6],
        );
    };
    subtest "spec: code(w/o sortsub) + strings + regex(w/o sortsub) (tests ordering)" => sub {
        is_deeply(
            sort_by_spec(spec=>[
                sub {$_[0] % 2} => sub {$_[1] <=> $_[0]},
                4,6,5,
                qr/[02468]\z/   => sub {$_[1] <=> $_[0]},
            ],
                         array=>[1..10]),
            [9,7,3,1,   4,6,5,   10,8,2],
        );
    };

    subtest "opt: xform" => sub {
        is_deeply(
            sort_by_spec(
                spec=>[3,5,4],
                array => [
                    {num=>1, str=>"foo"},
                    {num=>2, str=>"bar"},
                    {num=>3, str=>"baz"},
                    {num=>4, str=>"qux"},
                    {num=>5, str=>"quux"},
                ],
                xform=>sub {$_[0]{num}}
            ),
            [
                {num=>3, str=>"baz"},
                {num=>5, str=>"quux"},
                {num=>4, str=>"qux"},
                {num=>1, str=>"foo"},
                {num=>2, str=>"bar"},
            ],
        );
    };
};

# test opt: xform

done_testing;
