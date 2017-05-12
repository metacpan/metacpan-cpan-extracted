#!perl

use 5.010;
use strict;
use warnings;

use Sub::Iterator qw(gen_array_iterator);
use Test::Exception;
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'prop: result' => sub {
    my $sub_as_is = sub { my %args = @_; [200,"OK",\%args] };
    my $sub;
    my $meta;

    $sub  = sub {};
    $meta = {v=>1.1, result=>{foo=>1}};
    test_wrap(
        name      => 'unknown result spec key -> dies',
        wrap_args => {sub => $sub, meta => $meta},
        wrap_dies => 1,
    );

    $meta = {v=>1.1, result=>{x=>1, "x.y"=>2}};
    test_wrap(
        name      => 'result spec key x',
        wrap_args => {sub => $sub, meta => $meta},
    );

    $meta = {v=>1.1, result=>{_foo=>1}};
    test_wrap(
        name        => 'result spec key prefixed by _ is ignored',
        wrap_args   => {sub => $sub, meta => $meta},
    );

    $sub  = sub {};
    $meta = {v=>1.1};
    test_wrap(
        name      => 'wrapper checks that sub produces enveloped result',
        wrap_args => {sub => $sub, meta => $meta},
        calls     => [
            {argsr=>[], status=>500},
        ],
    );

    $sub  = sub {my %args = @_; [200, "OK", $args{err} ? "x":1]};
    $meta = {v=>1.1, args=>{err=>{}}, result=>{schema=>"int"}};
    test_wrap(
        name      => 'basics',
        wrap_args => {sub => $sub, meta => $meta},
        calls     => [
            {argsr=>[], status=>200},
            {argsr=>[err=>1], status=>500},
        ],
    );

    test_wrap(
        name      => 'opt: validate_result=0',
        wrap_args => {sub => $sub, meta => $meta, validate_result=>0},
        calls     => [
            {argsr=>[], status=>200},
            {argsr=>[err=>1], status=>200},
        ],
    );

    $meta = {v=>1.1, result=>{stream=>1}};
    test_wrap(
        name      => 'stream (scalar result -> err)',
        wrap_args => {sub => sub{[200,"OK",1]}, meta => $meta},
        calls     => [
            {argsr=>[], status=>500},
        ],
    );
    test_wrap(
        name      => 'stream (filehandle result -> ok)',
        wrap_args => {
            sub => sub{
                open my($fh), "<", $INC{'Perinci/Sub/Wrapper.pm'};
                [200,"OK",sub{~~<$fh>}];
            },
            meta => $meta,
        },
        calls     => [
            {argsr=>[], status=>200},
        ],
    );

    test_wrap(
        name      => 'stream (validation on each record)',
        wrap_args => {
            sub => sub{
                [200, "OK", gen_array_iterator([1,2,"x"])];
            },
            meta => {
                v => 1.1,
                result => {
                    schema => ['array', of=>'int*'],
                    stream => 1,
                },
            },
        },
        posttest => sub {
            my ($wrap_res, $call_res, $sub) = @_;
            my $res = $sub->();
            is($res->[0], 200, "status is 200");
            is(ref($res->[2]), "CODE", "returns coderef");
            is($res->[2]->(), 1);
            is($res->[2]->(), 2);
            dies_ok { $res->[2]->e() } 'third record not an int -> dies';
        },
    );
};

done_testing;
