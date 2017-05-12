#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Perinci::Sub::Util qw(gen_modified_sub);

package Foo;

our %SPEC;
$SPEC{bar} = {
    v => 1.1,
    summary => 'Orig summary',
    description => 'Orig description',
    args => {
        a => {_a=>1},
        b => {_b=>1},
        c => {_c=>1},
        d => {_d=>1},
        e => {_e=>1},
    },
};
sub bar {}

package main;

my $res = gen_modified_sub(
    base_name    => 'Foo::bar',
    summary      => 'Mod summary',
    description  => 'Mod description',
    remove_args  => ['a', 'b'],
    add_args     => {x => {_x=>1}},
    replace_args => {c => {_c=>2}},
    rename_args  => {d => 'j'},
    modify_args  => {e => sub { my $as=shift; $as->{_e}=2 }},
    modify_meta  => sub { my $m=shift; $m->{_mod}=1 },
);

is($res->[0], 200);
my $code = $res->[2]{code};
my $meta = $res->[2]{meta};
is_deeply($meta, {
    v => 1.1,
    summary => 'Mod summary',
    description => 'Mod description',
    args => {
        c => {_c=>2},
        e => {_e=>2},
        j => {_d=>1},
        x => {_x=>1},
    },
    _mod => 1,
}) or diag explain $meta;

# XXX test install (output_name)
# XXX test using caller in base_name
# XXX test base_code + base_meta
# XXX test not specifying base_*
# XXX test check in add_args, remove_args, replace_args, rename_args
# XXX test using caller in output_name

DONE_TESTING:
done_testing;
