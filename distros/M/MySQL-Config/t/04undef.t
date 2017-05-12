#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;

use Cwd qw(cwd);
use File::Spec;
use MySQL::Config qw(load_defaults);
use Test::More;

plan tests => 7;

$MySQL::Config::GLOBAL_CNF = File::Spec->catfile(cwd, qw(t my.cnf));

@ARGV = ('--one=1', '--two=2', '--three=3');
my $count = 0;

# XXX Can't test undef groups -- Since the user's ~/.my.cnf and
# /etc/my.cnf are read, who knows what will come back?

# Test undef name, argc, and argv
load_defaults undef, [ 'foo' ];

is(scalar @ARGV, 6, "scalar(\@ARGV) == " . scalar(@ARGV));
is($ARGV[0], '--one=1', '--one=1');
is($ARGV[1], '--two=2', '--two=2');
is($ARGV[2], '--three=3', '--three=3');
is($ARGV[3], '--bar=baz', '--bar=baz');
is($ARGV[4], '--quux="hoopy frood"', '--quux="hoopy frood"');
is($ARGV[5], '--my-foot-hurts=1', '--my-foot-hurts=1');

