#!/usr/bin/perl -w

use strict;

use Test::More tests => 37;

BEGIN
{
  use_ok('Rose::URI');
}

#
# new()
#

my $uri = Rose::URI->new('/baz?a=1&a=2&b=3');
is($uri->query, 'a=1&a=2&b=3', 'parse simple (&)');

$uri = Rose::URI->new('/baz?a=1;a=2;b=3');
is($uri->query, 'a=1&a=2&b=3', 'parse simple (;)');

#
# query_param_separator()
#

$uri->query_param_separator(';');
is($uri->query, 'a=1;a=2;b=3', 'switch separator');

$uri->query_param_separator('&');
is($uri->query, 'a=1&a=2&b=3', 'switch separator');

#
# query()
#

$uri->query('foo+bar');
is($uri->as_string, '/baz?foo%20bar', 'get/set string (keywords) 0');
is($uri->query, 'foo%20bar', 'get/set string (keywords) 1');
ok($uri->query_param_exists('foo bar'), 'get/set string (keywords) 2');
$uri->query_param_delete('xxx');
ok($uri->query_param_exists('foo bar'), 'get/set string (keywords) 2.1');
$uri->query_param_delete('foo bar');
ok(!$uri->query_param_exists('foo bar'), 'get/set string (keywords) 2.2');

$uri->query('foo');
is($uri->query, 'foo', 'get/set string (keywords) 3');
ok($uri->query_param_exists('foo'), 'get/set string (keywords) 4');

$uri->query("a=1&a=2&b=3");
is($uri->query, 'a=1&a=2&b=3', 'get/set string (&)');

$uri->query("a=1;a=2;b=3+4+5");
is($uri->query, 'a=1&a=2&b=3%204%205', 'get/set string (;)');

$uri->query({ a => [ 1, 2 ], b => 3 });
is($uri->query, 'a=1&a=2&b=3', 'get/set hash');

$uri->query(a => [ 1, 2 ], b => 3);
is($uri->query, 'a=1&a=2&b=3', 'get/set list');

#
# query_param()
#

$uri->query_param('b' => 4);
ok($uri->query_param('b', 4), 'get/set scalar');

$uri->query_param('a' => [ 11, 12 ]);
my $a = $uri->query_param('a');
ok(ref $a eq 'ARRAY' && @$a == 2 && $a->[0] == 11 && $a->[1] == 12, 'get/set array ref');

$uri->query_param('b' => 3);
my $b = $uri->query_params('b');
ok(ref $b eq 'ARRAY' && @$b == 1 && $b->[0] == 3, 'get array ref (single)');

$uri->query_param('a' => [ 1, 2 ]);
$a = $uri->query_params('a');
ok(ref $a eq 'ARRAY' && @$a == 2 && $a->[0] == 1 && $a->[1] == 2, 'get array ref (multiple)');

#
# query_params()
#

$uri->query_params('b' => 4);
my @b = $uri->query_params('b');
ok(@b == 1 && $b[0] == 4, 'get array (single)');

$uri->query_params('a' => [ 11, 12 ]);
my @a = $uri->query_params('a');
ok(@a == 2 && $a[0] == 11 && $a[1] == 12, 'get array (multiple)');

#
# query_form()
#

$uri->query_form(a => 1, a => 2, b => 3);
my @f = $uri->query_form;
ok(@f == 6 && $f[0] eq 'a' && $f[1] == 1 && 
              $f[2] eq 'a' && $f[3] == 2 &&
              $f[4] eq 'b' && $f[5] == 3, 'list');

#
# query_hash()
#

my $h = $uri->query_hash;
ok(keys(%$h) == 2 && ref $h eq 'HASH' &&
                     $h->{'a'}[0] == 1 &&
                     $h->{'a'}[1] == 2 &&
                     $h->{'b'}    == 3, 'hash ref');

my %h = $uri->query_hash;
ok(keys(%h) == 2 && $h{'a'}[0] == 1 &&
                    $h{'a'}[1] == 2 &&
                    $h{'b'}    == 3, 'hash');

#
# query_param_add()
#

$uri->query_param_add(b => 4);
@b = $uri->query_params('b');
ok(@b == 2 && $b[0] == 3 && $b[1] == 4, 'scalar');

$uri->query_param_add(b => [ 5, 6 ]);
@b = $uri->query_params('b');
ok(@b == 4 && $b[0] == 3 && $b[1] == 4 &&  $b[2] == 5 &&  $b[3] == 6, 'array ref');

#
# query_param_exists()
#

ok($uri->query_param_exists('a'), 'exists');

ok(!$uri->query_param_exists('z'), 'not exists');

#
# query_param_delete()
#

$uri->query_param_delete('b');
ok(!$uri->query_param_exists('b'), 'delete');

$uri->query_param('c' => 5);
is($uri->query, 'a=1&a=2&c=5', 'Final check');

#
# omit_empty_query_params()
#

$uri = Rose::URI->new('/baz?aye=1&aye=2&b=&cee=3&dee=&eee=4');

is(ref($uri)->default_omit_empty_query_params, 0, 'default_omit_empty_query_params');
is($uri->omit_empty_query_params, 0, 'omit_empty_query_params default');

is($uri->query, 'aye=1&aye=2&b=&cee=3&dee=&eee=4', 'query omit_empty_query_params(0) 1');

Rose::URI->default_omit_empty_query_params(1);

is($uri->query, 'aye=1&aye=2&cee=3&eee=4', 'query default_omit_empty_query_params(1)');

Rose::URI->default_omit_empty_query_params(0);

is($uri->query, 'aye=1&aye=2&b=&cee=3&dee=&eee=4', 'query omit_empty_query_params(0) 2');

$uri->omit_empty_query_params(1);

is($uri->query, 'aye=1&aye=2&cee=3&eee=4', 'query omit_empty_query_params(1)');
