#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

plan tests => 13;

# Tests:
# * Dependency methods

my $TEST_REPO = 't/data/repo';

my $sbokeeper = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);

my @deps = $sbokeeper->real_immediate_dependencies('f');
is_deeply(\@deps, ['a', 'b', 'e'], 'real_immediate_dependencies works');

@deps = $sbokeeper->real_dependencies('f');
is_deeply(\@deps, ['a', 'b', 'c', 'd', 'e'], 'real_dependencies works');

$sbokeeper->add(['f'], 1);

foreach my $p (qw(a b c d e)) {
	ok($sbokeeper->is_dependency($p, 'f'), 'is_dependency works');
}

@deps = $sbokeeper->immediate_dependencies('f');
is_deeply(\@deps, ['a', 'b', 'e'], 'immediate_dependencies works');

@deps = $sbokeeper->dependencies('f');
is_deeply(\@deps, ['a', 'b', 'c', 'd', 'e'], 'dependencies works');

my @rm = $sbokeeper->depremove('f', ['a']);
@deps = $sbokeeper->immediate_dependencies('f');

is_deeply(\@deps, ['b', 'e'], 'depremoved dependencies no longer tracked');
is_deeply(\@rm, ['a'], 'depremove removed dependencies');

my @add = $sbokeeper->depadd('f', ['a']);
@deps = $sbokeeper->immediate_dependencies('f');

is_deeply(\@deps, ['a', 'b', 'e'], 'depadded dependencies tracked');
is_deeply(\@add, ['a'], 'depadd added dependencies');
