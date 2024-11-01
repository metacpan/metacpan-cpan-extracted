#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

plan tests => 2;

# Tests:
# * write (which in turn tests dump)
# * new w/ json file argument

my $TEST_REPO = 't/data/repo';
my $TEST_JSON = 'test.json';

my $writer = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);

my @ideality = qw(a b c d e f);

$writer->add(['f'], 1);

$writer->write($TEST_JSON, 1);

ok(-s $TEST_JSON, 'write created json file');

my $reader = Slackware::SBoKeeper->new(
	$TEST_JSON,
	$TEST_REPO
);

my @pkgs = $reader->packages('all');

is_deeply(\@pkgs, \@ideality, 'JSON file ok, all packages found');

END {
	unlink $TEST_JSON if -e $TEST_JSON;
}
