#!perl

# test spec generation and the generated spec

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Test::More 0.96;
require "testlib.pl";

my ($table_data, $table_def) = gen_test_data();

test_gen(
    name => 'pk must be in fields',
    table_data => [],
    table_def  => {
        fields => {
            a => {schema=>'int*', index=>0, },
        },
        pk => 'b',
    },
    status => 400,
);

test_gen(
    name => 'pk must exist in table_def',
    table_data => [],
    table_def  => {
        fields => {
            a => {schema=>'int*', index=>0, },
        },
    },
    status => 400,
);

test_gen(
    name => 'fields must exist in table_def',
    table_data => [],
    table_def  => {
    },
    status => 400,
);

test_gen(
    name => 'fields in sort must exist in fields',
    table_data => [],
    table_def  => {
        fields => {
            a => {schema=>'int*', index=>0, },
        },
    },
    status => 400,
);

test_gen(
    name => 'spec generation',
    table_data => [],
    table_def  => $table_def,
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        ok($meta->{result}{table}, "result/table property generated");

        for (qw/b b.is/) {
            ok($args->{$_}, "boolean filter arg '$_' generated");
        }
        for (qw/i i.is i.in i.not_in i.min i.xmin i.max i.xmax/) {
            ok($args->{$_}, "int filter arg '$_' generated");
        }
        for (qw/f f.is f.in f.not_in f.min f.xmin f.max f.xmax/) {
            ok($args->{$_}, "float filter arg '$_' generated");
        }
        for (qw/a a.has a.lacks/) {
            ok($args->{$_}, "array filter arg '$_' generated");
        }
        for (qw/s s.is s.in s.not_in s.contains s.not_contains
                s.matches s.not_matches/) {
            ok($args->{$_}, "str filter arg '$_' generated");
        }
        for (qw/s2 s2.is s2.in s2.not_in s2.contains s2.not_contains
                s2.matches s2.not_matches/) {
            ok(!$args->{$_}, "str filter arg '$_' NOT generated");
        }
        for (qw/s3 s3.is s3.in s3.not_in s3.contains s3.not_contains/) {
            ok($args->{$_}, "str filter arg '$_' generated");
        }
        for (qw/s3.matches s3.not_matches/) {
            ok(!$args->{$_}, "str filter arg '$_' NOT generated");
        }
        for (qw/d d.is d.in d.not_in d.min d.xmin d.max d.xmax/) {
            ok($args->{$_}, "date filter arg '$_' generated");
        }
    },
);

test_gen(
    name => 'disable filtering',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_filtering=>0},
    post_test => sub {
        my ($res) = @_;
        my $meta = $res->[2]{meta};
        ok(!$meta->{args}{'b'}, 'b');
        ok(!$meta->{args}{'b.is'}, 'b.is');
        ok(!$meta->{args}{s3}, 's3');
    },
);

test_gen(
    name => 'disable search',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_search=>0},
    # test_gen will test that the 'q' argument is not produced
);

test_gen(
    name => 'disable field selection',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_field_selection=>0},
    # test_gen will test that the 'fields' argument is not produced
);

test_gen(
    name => 'disable ordering',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_ordering=>0},
    # test_gen will test that the 'sort' & 'random' arguments are not produced
);

test_gen(
    name => 'disable random ordering',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_ordering=>1, enable_random_ordering=>0},
    # test_gen will test that the 'random' argument is not produced
);

test_gen(
    name => 'disable paging',
    table_data => [],
    table_def  => $table_def,
    other_args => {enable_paging=>0},
    # test_gen will test that the 'result_*' arguments are not produced
);

test_gen(
    name => 'default_sort',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_sort=>["s"]},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        my $fres;
        $fres = $func->(detail=>1);
        subtest "default_sort s" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            my @r = map {$_->{s}} @{$fres->[2]};
            is_deeply(\@r, [qw/a1 a2 a3 b1/], "sort result")
                or diag explain \@r;
        };
    },
);

test_gen(
    name => 'default_random',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_random=>1},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        test_random_order($func, {}, 50, [qw/a1 a2 a3 b1/],
                          "sort result");
    },
);

test_gen(
    name => 'default_fields',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_fields=>'s,b'},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        my $fres;
        $fres = $func->();
        subtest "default_fields s,b" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            is_deeply($fres->[2], [
                ['a1', 0],
                ['b1', 0],
                ['a3', 1],
                ['a2', 1],
            ], "sort result")
                or diag explain $fres->[2];
        };
    },
);

test_gen(
    name => 'default_detail',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_detail=>1},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        my $fres;
        $fres = $func->();
        subtest "default_detail 1" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            is_deeply($fres->[2], $table_data, "sort result")
                or diag explain $fres->[2];
        };
    },
);

test_gen(
    name => 'default_with_field_names',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_with_field_names=>0},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};
        my $meta = $res->[2]{meta};
        my $args = $meta->{args};

        my $fres;
        $fres = $func->(fields=>['s', 'b']);
        subtest "default_with_field_names 0" => sub {
            is($fres->[0], 200, "status")
                or diag explain $fres;
            is_deeply($fres->[2],
                      [['a1', 0],
                       ['b1', 0],
                       ['a3', 1],
                       ['a2', 1]],
                      "sort result")
                or diag explain $fres->[2];
        };
    },
);

test_gen(
    name => 'default_result_limit',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {default_result_limit=>2},
    post_test => sub {
        my ($res) = @_;
        my $func = $res->[2]{code};

        test_query($func, {}, 2, 'default result_limit');
        test_query($func, {result_limit=>3}, 3, 'explicit result_limit');
    },
);

test_gen(
    name => 'option: extra_args',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {extra_args => {foo=>{}, bar=>{schema=>'int*'}}},
    post_test => sub {
        my ($res) = @_;
        my $meta = $res->[2]{meta};
        is_deeply($meta->{args}{foo}, {}, "foo");
        is_deeply($meta->{args}{bar}, {schema=>'int*'}, "bar");
    },
);

{
    my $table_def = {
        fields => {
            f1 => {schema=>'str*', pos=>0 },
            f2 => {schema=>'str*', pos=>1 },
            f3 => {schema=>'str*', pos=>2, include_by_default=>0 },
        },
        pk => 'f1',
    };
    my $table_data = [[qw/r11 r12 r13/]];

    test_gen(
        name => 'field spec property: include_by_default=0',
        table_data => $table_data,
        table_def  => $table_def,
        post_test => sub {
            my ($res) = @_;
            my $func = $res->[2]{code};
            my $meta = $res->[2]{meta};
            ok($meta->{args}{'with.f3'}, "'with.F' arg generated");
            is_deeply($func->(detail=>1, with_field_names=>0)->[2],
                      [[qw/r11 r12/]],
                      'f3 not included by default');
            is_deeply($func->(detail=>1,with_field_names=>0, 'with.f3'=>1)->[2],
                      [[qw/r11 r12 r13/]],
                      'f3 included via with.f3');
        },
    );
}

test_gen(
    name => 'option: extra_props',
    table_data => $table_data,
    table_def  => $table_def,
    other_args => {extra_props => {'x.foo'=>1, 'x.bar'=>[]}},
    post_test => sub {
        my ($res) = @_;
        my $meta = $res->[2]{meta};
        is_deeply($meta->{'x.foo'}, 1, "x.foo");
        is_deeply($meta->{'x.bar'}, [], "x.bar");
    },
);


DONE_TESTING:
done_testing();
