#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Sub::ConvertArgs::Array qw(convert_args_to_array);

my $meta10 = {args=>{a=>["int" => {arg_pos=>0}]}};
test_convertargs(
    name=>"meta v1.0 -> dies",
    meta=>$meta10, args=>{a=>1},
    status=>412,
);

my $meta;

$meta = {
    v => 1.1,
    args => {
        arg1 => {meta=>'str*'},
    },
};
test_convertargs(
    name=>'empty -> ok',
    meta=>$meta, args=>{},
    status=>200, array=>[],
);
test_convertargs(
    name=>'no meta -> error',
    meta=>$meta, args=>{arg2=>1},
    status=>412,
);

$meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>'str*', pos=>0},
        arg2 => {schema=>'str*', pos=>1},
    },
};
test_convertargs(
    name=>'arg1 only',
    meta=>$meta, args=>{arg1=>1},
    status=>200, array=>[1],
);
test_convertargs(
    name=>'arg2 only',
    meta=>$meta, args=>{arg2=>2},
    status=>200, array=>[undef, 2],
);
test_convertargs(
    name=>'arg1 & arg2 (1)',
    meta=>$meta, args=>{arg1=>1, arg2=>2},
    status=>200, array=>[1,2],
);
test_convertargs(
    name=>'arg1 & arg2 (2)',
    meta=>$meta, args=>{arg1=>2, arg2=>1},
    status=>200, array=>[2, 1],
);

$meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>['array*' => {of=>'str*'}], pos=>0, greedy=>1},
    },
};
test_convertargs(
    name=>'arg_greedy (1a)',
    meta=>$meta, args=>{arg1=>[1, 2, 3]},
    status=>200, array=>[1, 2, 3],
);
test_convertargs(
    name=>'arg_greedy (1b)',
    meta=>$meta, args=>{arg1=>2},
    status=>200, array=>[2],
);

$meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>'str*', pos=>0},
        arg2 => {schema=>['array*' => {of=>'str*'}], pos=>1, greedy=>1},
    },
};
test_convertargs(
    name=>'arg_greedy (2)',
    meta=>$meta, args=>{arg1=>1, arg2=>[2, 3, 4]},
    status=>200, array=>[1, 2, 3, 4],
);

DONE_TESTING:
done_testing();

sub test_convertargs {
    my (%args) = @_;

    subtest $args{name} => sub {
        my %input_args = (args=>$args{args}, meta=>$args{meta});

        my $res;
        eval { $res = convert_args_to_array(%input_args) };
        my $eval_err = $@;
        if ($args{dies}) {
            ok($eval_err, "dies");
        } else {
            ok(!$eval_err, "doesn't die") or diag "dies: $eval_err";
        }

        is($res->[0], $args{status}, "status=$args{status}")
            or diag explain $res;

        if ($args{array}) {
            is_deeply($res->[2], $args{array}, "result")
                or diag explain $res->[2];
        }
        #if ($args{post_test}) {
        #    $args{post_test}->();
        #}
    };
}
