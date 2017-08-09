#!perl -T

use strict;
use warnings;
use Storable qw(freeze);
use Struct::Diff qw(valid_diff);
use Test::More tests => 14;

use lib "t";
use _common qw(scmp);

local $Storable::canonical = 1; # to have equal snapshots for equal by data hashes

my (@got, @exp);

### scalar context
is(
    valid_diff({}),
    1,
    "Empty HASH is a valid diff"
);

is(
    valid_diff(sub { 0 }),
    undef,
    "Diff must be a HASH"
);

is(
    valid_diff({D => undef}),
    undef,
    "Wrong D value type"
);

### list context
@got = valid_diff(
    []
);
@exp = ([],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => {one => undef}}
);
@exp = ([{keys => ['one']}],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [undef]}
);
@exp = ([[0]],'BAD_DIFF_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => undef}
);
@exp = ([],'BAD_D_TYPE');
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [{D => 0},{D => 0}]}
);
@exp = (
    [[0]],'BAD_D_TYPE',
    [[1]],'BAD_D_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => {a => {D => 1},b => {D => 1}}}
);
@exp = (
    [{keys => ['a']}],'BAD_D_TYPE',
    [{keys => ['b']}],'BAD_D_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

@got = valid_diff(
    {D => [{D => 0},{N => 1},undef]}
);
@exp = (
    [[0]],'BAD_D_TYPE',
    [[2]],'BAD_DIFF_TYPE'
);
is_deeply(\@got, \@exp) || diag scmp(\@got, \@exp);

### indexes
ok(not valid_diff({D => [{A => 0, I => undef}]}));

@got = valid_diff(
    {
        D => [
            {A => 0, I => undef},
            {A => 0, I => 9},
            {A => 0, I => 0.3},
            {A => 0, I => 'foo'},
            {A => 0, I => sub { 0 }},
            {A => 0, I => -1},
            {A => 0, I => bless {}, 'foo'},
        ]
    }
);
@exp = (
    [[0]],'BAD_I_TYPE',
    [[2]],'BAD_I_TYPE',
    [[3]],'BAD_I_TYPE',
    [[4]],'BAD_I_TYPE',
    [[6]],'BAD_I_TYPE'
);
is_deeply(\@got, \@exp, "Integers permitted only") || diag scmp(\@got, \@exp);

is(
    valid_diff({I => 2}),
    undef,
    "Lonesome I, scalar context"
);

@got = valid_diff({I => 9});
@exp = (
    [],'LONESOME_I'
);
is_deeply(\@got, \@exp, "Integers permitted only") || diag scmp(\@got, \@exp);

