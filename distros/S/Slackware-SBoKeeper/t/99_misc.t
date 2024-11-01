#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

plan tests => 2;

# Tests:
# * unmanual
# * is_manual
# * extradeps

my $TEST_REPO = 't/data/repo';
my $TMP_JSON  = 'tmp.json';

my $sbokeeper = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);

$sbokeeper->add(['f'], 1);

$sbokeeper->unmanual('f');
is($sbokeeper->is_manual('f'), 0, 'unmanual works');

my %ideality = ('a' => ['c', 'd']);

$sbokeeper->add(['a'], 1);
$sbokeeper->depadd('a', ['c', 'd']);

my %extra = $sbokeeper->extradeps();
is_deeply(\%extra, \%ideality, 'extradeps works');

