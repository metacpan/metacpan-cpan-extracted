#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

# Tests:
# * add
# * exists
# * has
# * remove
# * tack

plan tests => 20;

my $TEST_REPO = 't/data/repo';

my $sbokeeper = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);

# List of packages that should be present in database.
my @ideality = qw(a b c d e f);

# f should pull other packages from @ideality
my @add  = $sbokeeper->add(['f'], 1);
my @pkgs = $sbokeeper->packages('all');

is_deeply(\@add, \@pkgs,     'Package list and add agree');
is_deeply(\@add, \@ideality, 'add pulled in correct packages');

foreach my $p (@ideality) {
	ok($sbokeeper->exists($p), 'exists method works');
	ok($sbokeeper->has($p),    'has method works');
}
ok(!$sbokeeper->exists('@fakepkg'),     'exists does not find fake packages');
ok(!$sbokeeper->has('@fakepkg'),        'has does not find fake packages');
ok($sbokeeper->exists('%README%'),      '%README% is considered real');

my @rm = $sbokeeper->remove(\@ideality);

is_deeply(\@rm, \@ideality, 'remove removed correct packages');

@ideality = qw(f);

@add = $sbokeeper->tack(['f'], 1);

is_deeply(\@add, \@ideality, 'tack added correct packages');

$sbokeeper->remove(\@add);

@ideality = qw(a c d multiline);

@add = $sbokeeper->add(['multiline'], 1);

is_deeply(\@add, \@ideality, 'add can handle multiline REQUIRES');
