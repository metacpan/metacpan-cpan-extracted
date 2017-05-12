#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'arg: validate_args' => sub {
    my $meta = {v=>1.1,
                args=>{a=>{pos=>0, req=>1, schema=>"int"},
                       b=>{pos=>1, schema=>["int", default=>2]}}};
    my $sub = sub { my %args = @_; [200,"OK",$args{b}] };
    test_wrap(
        name => 'validate_args=1 (default)',
        wrap_args => {sub=>$sub, meta=>$meta},
        calls => [
            {argsr=>[a=>1, c=>1], status=>400}, # unknown arg
            {argsr=>[], status=>400}, # missing required arg
            {argsr=>[a=>1, b=>"x"], status=>400}, # invalid arg
            {argsr=>[-x=>1, a=>1], status=>200}, # special arg is allowed
            {argsr=>[a=>1], status=>200, actual_res=>2}, # optional arg missing is ok, default supplied
            {argsr=>[a=>1, b=>1], status=>200}, # normal ok
        ],
    );
    test_wrap(
        name => 'validate_args=0',
        wrap_args => {sub=>$sub, meta=>$meta, validate_args=>0},
        calls => [
            {argsr=>[a=>1, c=>1], status=>200}, # unknown arg
            {argsr=>[], status=>200}, # missing required arg
            {argsr=>[a=>1, b=>"x"], status=>200}, # invalid arg
            {argsr=>[-x=>1, a=>1], status=>200}, # special arg is allowed
            {argsr=>[a=>1], status=>200, actual_res=>undef}, # optional arg missing is ok, default NOT supplied
            {argsr=>[a=>1, b=>1], status=>200}, # normal ok
        ],
    );
};

DONE_TESTING:
done_testing;
