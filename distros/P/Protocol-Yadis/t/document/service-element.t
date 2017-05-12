use Test::More tests => 14;

use Protocol::Yadis::Document::Service::Element;

my $e = Protocol::Yadis::Document::Service::Element->new;

is("$e", '');

$e->name('Type');
is("$e", '<Type></Type>');
ok(not defined $e->attr('a'));

$e->name('Type');
$e->content('foo');
is("$e", '<Type>foo</Type>');

$e->name('Type');
$e->attrs([a => 'b']);
$e->content('foo');
is("$e", '<Type a="b">foo</Type>');
is($e->attr('a'), 'b');

$e->name('Type');
$e->attrs([a => 'b', c => 'd']);
$e->content('foo');
is("$e", '<Type a="b" c="d">foo</Type>');
is($e->attr('a'), 'b');
is($e->attr('c'), 'd');

$e->name('Type');
$e->attr(a => 'b');
$e->attr(c => 'd');
$e->content('foo');
is("$e", '<Type a="b" c="d">foo</Type>');
$e->attr(c => 'a');
is("$e", '<Type a="b" c="a">foo</Type>');
is($e->attr('a'), 'b');
is($e->attr('c'), 'a');

$e->name('URI');
$e->attrs([]);
$e->content('');
$e->attr(priority => 10);
is("$e", '<URI priority="10"></URI>');
