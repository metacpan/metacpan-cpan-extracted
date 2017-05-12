#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'prop: result_naked' => sub {
    my $meta = {v=>1.1,
                args=>{a=>{pos=>0, schema=>"int"},
                       b=>{pos=>1, schema=>"int"}}};
    test_wrap(
        name => 'convert result_naked 0->1',
        wrap_args => {sub => sub {my %args=@_;[200,"OK",$args{a}/$args{b}]}, meta => $meta, convert=>{result_naked=>1}},
        calls => [
            {argsr => [a=>12, b=>3], res => 4},
        ],
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $meta = $wrap_res->[2]{meta};
            ok($meta->{result_naked}, "new meta result_naked=1");
        },
    );
    $meta->{result_naked} = 1;
    test_wrap(
        name => 'convert result_naked 1->0',
        wrap_args => {sub => sub {my %args=@_;$args{a}/$args{b}}, meta => $meta, convert=>{result_naked=>0}},
        calls => [
            {argsr => [a=>12, b=>3], res => [200,"OK",4]},
        ],
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $meta = $wrap_res->[2]{meta};
            ok(!$meta->{result_naked}, "new meta result_naked=0");
        },
    );
};

DONE_TESTING:
done_testing;
