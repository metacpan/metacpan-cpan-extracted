#!perl

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Test::More 0.98;

use Perinci::Sub::Util::Args qw(
                                   args_by_tag
                                   argnames_by_tag
                                   func_args_by_tag
                                   func_argnames_by_tag
                                   call_with_its_args
                           );

my $meta = {
    v => 1.1,
    summary => 'My function one',
    args => {
        foo => {tags=>['t1', 't2']},
        bar => {tags=>['t2', 't3']},
        baz => {},
        qux => {tags=>['t4']},
    },
};

subtest args_by_tag => sub {
    my $args = {foo=>1, bar=>2, baz=>3};
    is_deeply({args_by_tag($meta, $args, 't1')}, {foo=>1});
    is_deeply({args_by_tag($meta, $args, 't2')}, {foo=>1, bar=>2});
    is_deeply({args_by_tag($meta, $args, '!t1')}, {bar=>2, baz=>3});
    is_deeply({args_by_tag($meta, $args, 't4')}, {});
    is_deeply({args_by_tag($meta, $args, 't5')}, {});
};

subtest argnames_by_tag => sub {
    is_deeply([argnames_by_tag($meta, 't1')], [qw/foo/]);
    is_deeply([argnames_by_tag($meta, 't2')], [qw/bar foo/]);
    is_deeply([argnames_by_tag($meta, '!t1')], [qw/bar baz qux/]);
    is_deeply([argnames_by_tag($meta, 't5')], [qw//]);
};

subtest func_args_by_tag => sub {
    local $main::SPEC{func1} = $meta;
    my $args = {foo=>1, bar=>2, baz=>3};
    is_deeply({func_args_by_tag('main::func1', $args, 't1')}, {foo=>1});
};

subtest func_argnames_by_tag => sub {
    local $main::SPEC{func1} = $meta;
    is_deeply([func_argnames_by_tag('main::func1', 't2')], [qw/bar foo/]);
};

subtest call_with_its_args => sub {
    no warnings 'once';
    local $main::SPEC{func1} = $meta;
    local *main::func1 = sub { my %args = @_; \%args };
    is_deeply(call_with_its_args('main::func1', {foo=>1, bar=>2, quux=>3}),
              {foo=>1, bar=>2});
};

DONE_TESTING:
done_testing;
