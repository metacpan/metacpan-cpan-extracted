#!/usr/bin/perl -w

use strict;
use blib;

use Test::More tests => 34;
use Test::Exception;
#use Data::Dumper;

BEGIN { use_ok('Search::Estraier') };

ok(my $cond = new Search::Estraier::Condition, 'new');
isa_ok($cond, 'Search::Estraier::Condition');

cmp_ok($cond->max, '==', -1, 'max');
cmp_ok($cond->options, '==', 0, 'options');

ok($cond->set_phrase('search'), 'set_phrase');
ok($cond->add_attr('@foo BAR baz'), 'set_attr');
ok($cond->set_order('@foo ASC'), 'set_order');
ok($cond->set_max(42), 'set_max, number');
throws_ok { $cond->set_max('foo') } qr/number/, 'set_max, NaN';

my $old_options = -1;
my @all_options = qw/SURE USUAL FAST AGITO NOIDF SIMPLE/;
my $all_opts = 0;
foreach my $opt (@all_options) {
	ok(my $options = $cond->set_options( $opt ), 'set_option '.$opt);
	cmp_ok($options, '!=', $old_options, "options changed");
	$old_options = $options;
	$all_opts += $options;
}

cmp_ok($cond->set_options(@all_options), '==', $all_opts, "set_option all!");

throws_ok { $cond->set_options('foo') } qr/foo/, "set_option invalid";

cmp_ok($cond->set_options( SURE => 1 ), '==', $cond->set_options('SURE'), "set_option backward compatibility");

ok($cond->set_mask(qw/0 1 2/), 'mask');

my $v;
cmp_ok($v = $cond->phrase, 'eq', 'search', "phrase: $v");
cmp_ok($v = $cond->max, '==', 42, "max: $v");
cmp_ok($v = $cond->options, '!=', 0, "options: $v");

#diag "attrs: ",join(",",$cond->attrs);
cmp_ok($cond->attrs, '==', 1, 'one attrs');
ok($cond->add_attr('@foo2 BAR2 baz2'), 'set_attr');
#diag "attrs: ",join(",",$cond->attrs);
cmp_ok($cond->attrs, '==', 2, 'two attrs');

ok($cond->set_distinct('@foo'), 'set_distinct');
cmp_ok($cond->distinct, 'eq', '@foo', 'distinct');
