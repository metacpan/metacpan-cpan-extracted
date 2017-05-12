#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'prop: args_rels' => sub {
    my $meta = {
        v=>1.1,
        args=>{a=>{}, b=>{}, c=>{}},
    };
    {
        local $meta->{args_rels} = {foo=>1};
        test_wrap(
            name => 'unknown property in args_rels -> wrap dies',
            wrap_args => {sub => sub {[200]}, meta => $meta},
            wrap_dies => 1,
        );
    }
    {
        local $meta->{args_rels} = {req_one=>["a","b"]};
        test_wrap(
            name => 'unknown property in args_rels -> wrap dies',
            wrap_args => {sub => sub {[200]}, meta => $meta},
            wrap_status => 200,
            calls => [
                {argsr=>[], status=>400},
                {argsr=>[a=>1, b=>1], status=>400},
                {argsr=>[a=>1], status=>200},
                {argsr=>[b=>1], status=>200},
            ],
        );
    }
};

DONE_TESTING:
done_testing;
