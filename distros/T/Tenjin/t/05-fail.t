#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Tenjin;
use Try::Tiny;

my $t = Tenjin->new({ path => ['t/data/fail'] });
ok($t, 'Got a proper Tenjin instance');

my $output = try { $t->render('fail.html') } catch { 'failed'; };

is(
	$output,
	'failed',
	'failure caught'
);

my $output2 = try { $t->render('no_fail.html') } catch { 'failed'; };

is(
	$output2,
	1,
	'all okay'
);
