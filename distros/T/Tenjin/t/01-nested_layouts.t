#!perl -T

use strict;
use warnings;
use Test::More;
use Tenjin;

my $t = Tenjin->new({ path => ['t/data/nested_layouts'] });
ok($t, 'Got a proper Tenjin instance');

# single-level layout
is(
	$t->render('inside_layout.html', { _content => 'fake' }),
	'<outside><inside>fake</inside></outside>',
	'Single level of layouts works'
);

# multiple-level layouts
is(
	$t->render('top.html'),
	'<outside><inside><top>content</top></inside></outside>',
	'Multiple levels of layouts work'
);

done_testing();
