#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Sub::GetArgs::Array qw(get_args_from_array);

my $meta;

$meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>'str*'},
    },
};
test_getargs(
    name=>'no arg -> ok',
    meta=>$meta, array=>[],
    status=>200, args=>{}, remaining_array=>[],
);
test_getargs(
    name=>'extra arg -> 400',
    meta=>$meta, array=>[1],
    status=>400,
);
test_getargs(
    name=>'allow_extra_elems=1',
    meta=>$meta, array=>[1], allow_extra_elems=>1,
    status=>200, array=>[],
);

$meta = {
    v => 1.1,
    args => {
        arg1 => {schema=>['str*' => {}], pos=>0},
        arg2 => {schema=>['str*' => {}], pos=>1},
    },
};
test_getargs(
    name=>'arg1 only',
    meta=>$meta, array=>[1],
    status=>200, args=>{arg1=>1}, remaining_array=>[],
);
test_getargs(
    name=>'arg1 & arg2 (1)',
    meta=>$meta, array=>[1, 2],
    status=>200, args=>{arg1=>1, arg2=>2}, remaining_array=>[],
);
test_getargs(
    name=>'arg1 & arg2 (2)',
    meta=>$meta, array=>[2, 1],
    status=>200, args=>{arg1=>2, arg2=>1}, remaining_array=>[],
);

subtest "slurpy (str)" => sub {
    my $meta = {
        v => 1.1,
        args => {
            arg1 => {schema=>'str*', pos=>0},
            arg2 => {schema=>'str*', pos=>1, slurpy=>1},
        },
    };
    test_getargs(
        name=>'arg_slurpy (3, string)',
        meta=>$meta, array=>[1, 2, 3, 4],
        status=>200, args=>{arg1=>1, arg2=>"2 3 4"}, remaining_array=>[],
    );
};

subtest "slurpy (array)" => sub {
    my $meta = {
        v => 1.1,
        args => {
            arg1 => {schema => ['array*' => {of=>'str*'}], pos=>0, slurpy=>1},
        },
    };
    test_getargs(
        name=>'arg_slurpy (1)',
        meta=>$meta, array=>[1, 2, 3],
        status=>200, args=>{arg1=>[1, 2, 3]}, remaining_array=>[],
    );

    $meta = {
        v => 1.1,
        args => {
            arg1 => {schema=>'str*', pos=>0},
            arg2 => {schema=>['array*' => {of=>'str*'}], pos=>1, slurpy=>1},
        },
    };
    test_getargs(
        name=>'arg_slurpy (2)',
        meta=>$meta, array=>[1, 2, 3, 4],
        status=>200, args=>{arg1=>1, arg2=>[2, 3, 4]}, remaining_array=>[],
    );
};

subtest "slurpy (hash)" => sub {
    my $meta = {
        v => 1.1,
        args => {
            arg1 => {schema => ['hash*' => {of=>'str*'}], pos=>0, slurpy=>1},
        },
    };
    test_getargs(
        name=>'arg_slurpy (1)',
        meta=>$meta, array=>[qw/a=1 b=2 c=3/],
        status=>200, args=>{arg1=>{a=>1, b=>2, c=>3}}, remaining_array=>[],
    );

    $meta = {
        v => 1.1,
        args => {
            arg1 => {schema=>'str*', pos=>0},
            arg2 => {schema=>['hash*' => {of=>'str*'}], pos=>1, slurpy=>1},
        },
    };
    test_getargs(
        name=>'arg_slurpy (2)',
        meta=>$meta, array=>[qw/a=1 b=2 c=3 d=4/],
        status=>200, args=>{arg1=>'a=1', arg2=>{b=>2, c=>3, d=>4}}, remaining_array=>[],
    );
};

DONE_TESTING:
done_testing();

sub test_getargs {
    my (%args) = @_;

    subtest $args{name} => sub {
        my $ary = [ @{ $args{array} } ];
        my %input_args = (array=>$ary, meta=>$args{meta});
        for (qw/allow_extra_elems/) {
            $input_args{$_} = $args{$_} if defined $args{$_};
        }
        my $res = get_args_from_array(%input_args);

        is($res->[0], $args{status}, "status=$args{status}")
            or diag explain $res;

        if ($args{args}) {
            is_deeply($res->[2], $args{args}, "result")
                or diag explain $res->[2];
        }
        if ($args{remaining_array}) {
            is_deeply($ary, $args{remaining_array}, "remaining array")
                or diag explain $ary;
        }
        #if ($args{posttest}) {
        #    $args{posttest}->();
        #}

        done_testing();
    };
}
