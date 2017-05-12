#!perl -T

use strict;
use warnings;
use Test::More;
use Tenjin;

my $t = Tenjin->new({ path => ['t/data/capture_placeholder'] });
ok($t, 'Got a proper Tenjin instance');

my $context = { exists => 'hello world' };

# the capture() macro
is(
	$t->render('capture.html', $context),
	"hello world\nI don't have the noexist variable.\n",
	'capture works'
);

# the placeholder() macro
is(
	$t->render('placeholder.html', $context),
	"hello world\nI don't have the noexist variable.\n",
	'placeholder works'
);

done_testing();
