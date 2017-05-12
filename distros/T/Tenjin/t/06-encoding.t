#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Tenjin;
use utf8;

my $t = Tenjin->new({ path => ['t/data/encoding'] });
ok($t, 'Got a proper Tenjin instance');

is($t->render('hebrew.html'), "<h1>ג'רי סיינפלד</h1>\n", 'UTF-8 (Hebrew) properly decoded');

is($t->render('chinese.html'), "<a title=\"汉语/漢語\">Chinese</a>\n", 'UTF-8 (Chinese) properly decoded');
