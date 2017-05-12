#!perl -T

use strict;
use warnings;
use Test::More;
use Tenjin;

my $t = Tenjin->new({ path => ['t/data/layout_precedence'], layout => 'instance_layout.html' });
ok($t, 'Got a proper Tenjin instance');

my $context = { msg => 'hello world', arrayref => [qw/my name is Tenjin/] };

# no layout should be used
is(
	$t->render('content.html', $context, 0),
	'<p>hello world, my name is Tenjin</p>',
	'Rendering without a layout works'
);

# layout should be used from $_context->{_layout}
$context->{_layout} = 'context_layout.html';
is(
	$t->render('content.html', $context, 'render_layout.html'),
	'<xml><p>hello world, my name is Tenjin</p></xml>',
	'Rendering into context-defined layout works'
);

# layout should be used from render
is(
	$t->render('content.html', $context, 'render_layout.html'),
	'<html><p>hello world, my name is Tenjin</p></html>',
	'Rendering into render-defined layout works'
);

# layout should be used from Tenjin instance
is(
	$t->render('content.html', $context),
	'<null><p>hello world, my name is Tenjin</p></null>',
	'Rendering into instance-defined layout works'
);

done_testing();
