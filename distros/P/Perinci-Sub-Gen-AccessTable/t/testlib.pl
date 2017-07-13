use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Test::More 0.96;

sub test_gen {
    my (%args) = @_;

    subtest $args{name} => sub {
        my $res;
        my %fargs = (
            name       => 'foo',
            install    => $args{install} // 0,
            table_data => $args{table_data},
            table_spec => $args{table_spec},
        );
        if ($args{other_args}) {
            while (my ($k, $v) = each %{$args{other_args}}) {
                $fargs{$k} = $v;
            }
        }
        eval { $res = gen_read_table_func(%fargs) };
        my $eval_err = $@;
        diag "died during function: $eval_err" if $eval_err;

        if ($args{dies}) {
            ok($eval_err, "dies");
        }

        {
            my $status = $args{status} // 200;
            is($res->[0], $status, "status = $status") or
                do { diag explain $res; return };
        }

        if ($res->[0] == 200) {
            my $func = $res->[2]{code};
            my $meta = $res->[2]{meta};
            is(ref($func), 'CODE', 'func returned');
            is(ref($meta), 'HASH', 'meta returned');
            my $args = $meta->{args};
            for my $a (qw/with_field_names detail
                         /) {
                ok($args->{$a}, "common arg '$a' generated");
            }

            if (!defined($fargs{enable_field_selection}) || $fargs{enable_field_selection}) {
                ok( $args->{fields}, "field selection arg 'fields' generated");
            } else {
                ok(!$args->{fields}, "field selection arg 'fields' not generated");
            }

            if (!defined($fargs{enable_paging}) || $fargs{enable_paging}) {
                ok( $args->{result_limit}, "paging arg 'result_limit' generated");
                ok( $args->{result_start}, "paging arg 'result_start' generated");
            } else {
                ok(!$args->{result_limit}, "paging arg 'result_limit' not generated");
                ok(!$args->{result_start}, "paging arg 'result_start' not generated");
            }

            if (!defined($fargs{enable_ordering}) || $fargs{enable_ordering}) {
                ok( $args->{sort}, "ordering arg 'sort' generated");
            } else {
                ok(!$args->{sort}, "ordering arg 'sort' not generated");
            }

            if ((!defined($fargs{enable_ordering}) || $fargs{enable_ordering}) &&
                    (!defined($fargs{enable_random_ordering}) || $fargs{enable_random_ordering})) {
                ok( $args->{random}, "ordering arg 'random' generated");
            } else {
                ok(!$args->{random}, "ordering arg 'random' not generated");
            }

            if ((!defined($fargs{enable_filtering}) || $fargs{enable_filtering}) &&
                    (!defined($fargs{enable_search}) || $fargs{enable_search})) {
                ok( $args->{query}, "search arg 'query' generated");
            } else {
                ok(!$args->{query}, "search arg 'query' not generated");
            }
        }

        if ($args{post_test}) {
            $args{post_test}->($res);
        }
    };
}

sub gen_test_data {
    my ($aoa_data) = @_;

    my $table_data = [
        {s=>'a1', s2=>'', s3=>'a' , i=>1 , f=>0.1, a=>[qw//]     , b=>0, d=>'2014-01-02'},
        {s=>'b1', s2=>'', s3=>'aa', i=>2 , f=>0.2, a=>[qw/t2/]   , b=>0, d=>'2014-02-02'},
        {s=>'a3', s2=>'', s3=>'aa', i=>4 , f=>1.1, a=>[qw/t1 t2/], b=>1, d=>'2013-01-02'},
        {s=>'a2', s2=>'', s3=>'a' , i=>-3, f=>1.2, a=>[qw/t1/]   , b=>1, d=>'2013-02-02'},
    ];
    if ($aoa_data) {
        for my $r (@$table_data) {
            $r = [
                $r->{s}, $r->{s2}, $r->{s3},
                $r->{i}, $r->{f},  $r->{a},  $r->{b},
                $r->{d},
            ];
        }
    }

    my $table_spec = {
        fields => {
            # reminder: we still test the old 'index' property, support for it
            # will be removed someday
            s  => {schema=>'str*'   , pos=>0, filterable_regex=>1, },
            s2 => {schema=>'str*'   , pos=>1, filterable=>0, },
            s3 => {schema=>'str*'   , pos=>2, },
            i  => {schema=>'int*'   , pos=>3, },
            f  => {schema=>'float*' , pos=>4, },
            a  => {schema=>'array*' , pos=>5, sortable=>0, },
            b  => {schema=>'bool*'  , index=>6, },
            d  => {schema=>'date*'  , index=>7, },
        },
        pk => 's',
    };

    return ($table_data, $table_spec);
}

sub test_random_order {
    my ($func, $args, $n, $elems, $test_name) = @_;

    my @x;
    for (1 .. $n) {
        my $a = $func->(%$args)->[2];
        push @x, $a->[0] unless $a->[0] ~~ @x;
    }

    is_deeply([sort {$a cmp $b} @x],
              [sort {$a cmp $b} @$elems], "random order ($n runs)")
        or diag explain \@x;
}

sub test_query {
    my ($func, $args, $test, $name) = @_;

    my $res = $func->(%$args);
    subtest $name => sub {
        is($res->[0], 200, "status = 200")
            or diag explain $res;
        if (ref($test) eq 'CODE') {
            $test->($res->[2]);
        } else {
            is(scalar(@{$res->[2]}), $test, "num_results = $test")
                or diag explain $res->[2];
        }
    };

    $res->[2];
}

1;
