use strict;
use warnings;
use Test::More;
use Test::Deep;
use Panda::URI;

my $uri;

$uri = new Panda::URI("https://ya.ru/my/path?p1=v1&p2=v2&p3=a%20b&p2=v2v2&=empty&empty=&#myhash");

my $query = $uri->query;
is($query->{p1}, 'v1');
is($uri->param('p1'), 'v1');
cmp_deeply([$uri->multiparam('p1')], ['v1']);
is(scalar(keys %$query), 5);
is($uri->nparam, 7);
is($query->{p3}, 'a b');
is($uri->param('p3'), 'a b');
ok(exists $query->{empty});
is($query->{empty}, '');
is($uri->param('empty'), '');
ok(!defined $uri->param('nonexistent'));
ok(defined $query->{''});
ok(defined $uri->param(''));
cmp_bag([$uri->multiparam('')], ['', 'empty']);
ok($query->{p2});
ok($uri->param('p2'));
ok(!ref($query->{p2}));
ok(!ref($uri->param('p2')));
cmp_bag([$uri->multiparam('p2')], ['v2', 'v2v2']);

$uri->query({a => 1, "key space" => 2, b => "val space", multi => [1,2,3], "" => 'emtpy'});
my $qstr = $uri->query_string;
like($qstr, '/(^|&)a=1(&|$)/');
like($qstr, '/(^|&)key%20space=2(&|$)/');
like($qstr, '/(^|&)b=val%20space(&|$)/');
like($qstr, '/(^|&)multi=1(&|$)/');
like($qstr, '/(^|&)multi=2(&|$)/');
like($qstr, '/(^|&)multi=3(&|$)/');
like($qstr, '/(^|&)=emtpy(&|$)/');

$uri = new Panda::URI("https://ya.ru/my/path?a=b");
$uri->add_query('');
is($uri, "https://ya.ru/my/path?a=b");

$uri->query({a => 1});
$uri->add_query('c=d&e=f%20e');
like($uri->query_string, '/c=d/');
like($uri->query_string, '/e=f%20e/');
like($uri->query_string, '/a=1/');
is($uri->param('a'), '1');
is($uri->param('c'), 'd');
is($uri->param('e'), 'f e');

$uri = new Panda::URI("https://ya.ru/my/path?a=b");
$uri->query_string('a=1');
$uri->add_query(c => 'd', e => 'f e');
like($uri->query_string, '/c=d/');
like($uri->query_string, '/e=f%20e/');
like($uri->query_string, '/a=1/');
is($uri->param('a'), '1');
is($uri->param('c'), 'd');
is($uri->param('e'), 'f e');

$uri = new Panda::URI::http("https://ya.ru/my/path?a=b", {c => 'd e'});
like($uri, '/a=b/');
like($uri, '/c=d%20e/');
like($uri->query_string, '/a=b/');
like($uri->query_string, '/c=d%20e/');
is($uri->query->{a}, 'b');
is($uri->query->{c}, 'd e');

$uri = new Panda::URI::http("https://ya.ru/my/path?a=b", c => 'd e');
like($uri, '/a=b/');
like($uri, '/c=d%20e/');

$uri = new Panda::URI::http("https://ya.ru/my/path?a=b", 'c=d%20e');
like($uri, '/a=b/');
like($uri, '/c=d%20e/');

$uri = new Panda::URI("https://ya.ru/my/path?a=b;e=f;c=d%20e", PARAM_DELIM_SEMICOLON);
cmp_deeply($uri->query, {a => 'b', e => 'f', c => 'd e'});
like($uri->query_string, '/[^;]+;[^;]+;[^;]+/');

# bug test (no sync query for param())
$uri = Panda::URI->new("https://graph.facebook.com/v2.2?fields=id%2Cfirst_name%2Clast_name%2Cname%2Cgender%2Cbirthday%2Clink&ids=me&include_headers=false");
$uri->query_string('');
$uri->param('batch', 123);
is($uri, "https://graph.facebook.com/v2.2?batch=123");

done_testing();
