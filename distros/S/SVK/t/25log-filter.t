#!/usr/bin/perl -w
use strict;
use SVK::Test;
plan tests => 24;

# working copy initialization
our $output;
my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath();
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);
chdir ($copath);

# create some files, copy them and set a property
overwrite_file ("foo", "1\n");
$svk->add('foo');
$svk->commit('-m', 'init');
overwrite_file("foo", "2\n");
$svk->commit('-m', 'added a needle');
overwrite_file("foo", "3\n");
$svk->commit('-m', 'only hay this time');
overwrite_file("foo", "4\n");
$svk->commit('-m', 'needle and a lot of hay');

# set some author properties to test the author filter
$svk->ps(qw( --revprop -r 1 svn:author person  ));
$svk->ps(qw( --revprop -r 2 svn:author another ));
$svk->pd(qw( --revprop -r 3 svn:author         ));  # delete author
$svk->ps(qw( --revprop -r 4 svn:author person  ));

# sanity check the output
is_output(
    $svk, 'log', [],
    [
        qr/-+/,
        qr/r4:/,
        '',
        'needle and a lot of hay',
        qr/-+/,
        qr/r3:/,
        '',
        'only hay this time',
        qr/-+/,
        qr/r2:/,
        '',
        'added a needle',
        qr/-+/,
        qr/r1:/,
        '',
        'init',
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '-q', '--filter', 'grep needle' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);
is_output(
    $svk, 'log', [ '-q', '--filter', 'grep NEEDLE' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);
is_output(
    $svk, 'log', [ '-q', '--filter', 'grep (?-i)NEEDLE' ],
    [
        qr/-+/,
    ],
);
# make sure an escaped '|' is part of the pattern
is_output(
    $svk, 'log', [ '-q', '--filter', 'grep (needle\|hay)' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r3:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '-q', '--filter', 'head 2' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r3:/,
        qr/-+/,
    ],
);

# again, with space after the number...
is_output(
    $svk, 'log', [ '-q', '--filter', 'head 2 ' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r3:/,
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '-q', '--filter', 'grep needle | head 1' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
    ],
);

# There are two needle entries, but only one is in the first two, so
# "head | grep" only finds one, while "grep | head" and grep with
# --limit find both.

is_output(
    $svk, 'log', [ '-q', '--filter', 'head 2 | grep needle' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '-q', '--filter', 'grep needle | head 2' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '-q', '--limit', 2, '--filter', 'grep needle' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);

# the "init" message is not in the first two, so we should not find it
# if we "head 2" first.
is_output(
    $svk, 'log', [ '--filter', 'head 2 | grep init' ],
    [
        qr/-+/,
    ],
);

is_output(
    $svk, 'log', [ '--filter', 'grep init | head 2' ],
    [
        qr/-+/,
        qr/r1:/,
        '',
        'init',
        qr/-+/,
    ],
);

# author filter
is_output(
    $svk, 'log', [ '-q', '--filter', 'author person' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r1:/,
        qr/-+/,
    ],
);
is_output(
    $svk, 'log', [ '-q', '--filter', 'author person,another' ],
    [
        qr/-+/,
        qr/r4:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
        qr/r1:/,
        qr/-+/,
    ],
);
is_output(
    $svk, 'log', [ '-q', '--filter', 'author another, (none)' ],
    [
        qr/-+/,
        qr/r3:/,
        qr/-+/,
        qr/r2:/,
        qr/-+/,
    ],
);


# test some error conditions
is_output(
    $svk, 'log', [ '--filter', 'grep }{' ],
    [
        q(Grep: Invalid regular expression '}{'.),
    ],
);
is_output(
    $svk, 'log', [ '--filter', 'head blah' ],
    [
        q(Head: 'blah' is not numeric.),
    ],
);
is_output(
    $svk, 'log', [ '--filter', 'head' ],
    [
        q(Head: '' is not numeric.),
    ],
);
is_output(
    $svk, 'log', [ '--filter', 'author' ],
    [
        q(Author: at least one author name is required.),
    ],
);
is_output(
    $svk, 'log', [ '--filter', 'std' ],
    [
        q(Cannot use the output filter "std" in a selection pipeline.),
        q(Perhaps you meant "--output std".  If not, take a look at),
        q("svk help log" for examples of using log filters.),
    ],
);
is_output(
    $svk, 'log', [ '--filter', 'author joe | std' ],
    [
        q(Cannot use the output filter "std" in a selection pipeline.),
        q(Perhaps you meant "--output std".  If not, take a look at),
        q("svk help log" for examples of using log filters.),
    ],
);
is_output(
    $svk, 'log', [ '--output', 'grep' ],
    [
        q(Cannot use the selection filter "grep" as an output filter.),
        q(Perhaps you meant "--filter 'grep ...'".  If not, take a look at),
        q("svk help log" for examples of using log filters.),
    ],
);
is_output(
    $svk, 'log', [ '--output', 'std | xml' ],
    [
        q(Output filters cannot be chained in a pipeline.),
        q(See "svk help log" for examples of using log filters.),
    ],
);
