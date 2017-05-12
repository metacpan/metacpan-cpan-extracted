#!perl -T

use strict;
use warnings;
use Test::More;
use Tenjin;

my $t = Tenjin->new({ path => ['t/data/delete-newline'], cache => 0 });
ok($t, 'Got a proper Tenjin instance');

# should delete newline
is(
	$t->render('delete-newline.txt', { var => 'test' }),
	<<'EOF',
line
testanother line
EOF
	'Delete newline works'
);

# should do nothing and not corrupt text
is(
	$t->render('delete-no-newline.txt', { var => 'test' }),
	<<'EOF',
line
"test"
another line
EOF
	'Delete newline with no newline to delete works'
);

done_testing();
