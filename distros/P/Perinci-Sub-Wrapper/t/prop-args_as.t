#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'prop: args_as' => sub {
    my $meta = {v=>1.1,
                args=>{a=>{pos=>0, schema=>"int"},
                       b=>{pos=>1, schema=>"int"}}};
    {
        test_wrap(
            name => 'args_as=hash (default)',
            wrap_args => {sub => sub {my %args=@_; [200,"OK",$args{a}/$args{b}]}, meta => $meta},
            wrap_status => 200,
            calls => [
                {argsr=>[a=>10, b=>5], status=>200, actual_res=>2},
                {argsr=>[a=>12, b=>3], status=>200, actual_res=>4},
            ],
        );
    }
    {
        local $meta->{args_as} = 'hashref';
        test_wrap(
            name => 'args_as=hashref',
            wrap_args => {sub => sub {[200,"OK",$_[0]{a}/$_[0]{b}]}, meta => $meta},
            wrap_status => 200,
            calls => [
                {argsr=>[{a=>10, b=>5}], status=>200, actual_res=>2},
                {argsr=>[{a=>12, b=>3}], status=>200, actual_res=>4},
            ],
        );
    }
    {
        local $meta->{args_as} = 'array';
        test_wrap(
            name => 'args_as=array',
            wrap_args => {sub => sub {[200,"OK",$_[0]/$_[1]]}, meta => $meta},
            wrap_status => 200,
            calls => [
                {argsr=>[10, 5], status=>200, actual_res=>2},
                {argsr=>[12, 3], status=>200, actual_res=>4},
            ],
        );
    }
    {
        local $meta->{args_as} = 'arrayref';
        test_wrap(
            name => 'args_as=arrayref',
            wrap_args => {sub => sub {[200,"OK",$_[0][0]/$_[0][1]]}, meta => $meta},
            wrap_status => 200,
            calls => [
                {argsr=>[[10, 5]], status=>200, actual_res=>2},
                {argsr=>[[12, 3]], status=>200, actual_res=>4},
            ],
        );
    }
    {
        local $meta->{args_as} = 'hash';
        test_wrap(
            name => 'convert args_as hash -> array',
            wrap_args => {sub => sub {my %args=@_; [200,"OK",$args{a}/$args{b}]}, meta => $meta, convert=>{args_as=>'array'}},
            wrap_status => 200,
            calls => [
                {argsr=>[10, 5], status=>200, actual_res=>2},
                {argsr=>[12, 3], status=>200, actual_res=>4},
            ],
        );
    }
    # XXX convert hash->hashref
    # XXX convert hash->arrayref

    # XXX convert hashref->hash
    # XXX convert hashref->array
    # XXX convert hashref->arrayref

    {
        local $meta->{args_as} = 'array';
        test_wrap(
            name => 'convert args_as array -> hash',
            wrap_args => {sub => sub {[200,"OK",$_[0]/$_[1]]}, meta => $meta, convert=>{args_as=>'hash'}},
            wrap_status => 200,
            calls => [
                {argsr=>[a=>10, b=>5], status=>200, actual_res=>2},
                {argsr=>[a=>12, b=>3], status=>200, actual_res=>4},
            ],
        );
    }
    # XXX convert array->hashref
    # XXX convert array->arrayref

    # XXX convert arrayref->hash
    # XXX convert arrayref->hashref
    # XXX convert arrayref->array

    # XXX convert hash->array + slurpy
};

DONE_TESTING:
done_testing;
