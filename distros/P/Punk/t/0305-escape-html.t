#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use Punk::Test;

# $c->escape_html - the escape Punk writes its own markup with
# (include/punk/punk_escape.h), for Perl.

our $c;
eval <<'PERL' or die $@;
package EscapeApp;
use Punk;
get '/' => sub { $main::c = $_[0]; $_[0]->text('ok') };
1;
PERL
Punk::Test->new('EscapeApp')->get_ok('/')->status_is(200);
ok($c, 'a context to call it on');
sub esc { $c->escape_html(@_) }

is(esc(q{<a href="x" title='y'>Tom & Jerry</a>}),
   '&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;Tom &amp; Jerry&lt;/a&gt;',
   'the five characters become entities');
is(esc('plain text, 100% safe'), 'plain text, 100% safe', 'everything else is left alone');
is(esc(''), '', 'the empty string');
is(esc(undef), '', 'undef is the empty string');
is(esc(42), '42', 'a number is its string');
is(esc('&amp;'), '&amp;amp;', 'an entity is escaped again: the input is text, not markup');
is(esc("&&&"), '&amp;&amp;&amp;', 'runs of them');
is(esc("a\0<b"), "a\0&lt;b", 'a NUL does not end the string');

my $u = "caf\x{e9} \x{263a} <b>";
my $e = esc($u);
ok(utf8::is_utf8($e), 'a character string stays one');
is($e, "caf\x{e9} \x{263a} &lt;b&gt;", '  and its characters pass through');
my $bytes = "caf\xc3\xa9 <b>";
is(esc($bytes), "caf\xc3\xa9 &lt;b&gt;", 'UTF-8 bytes pass through as bytes');
ok(!utf8::is_utf8(esc($bytes)), '  and stay bytes');

my $long = ('x' x 10_000) . '<' . ('y' x 10_000);
is(length(esc($long)), 20_004, 'a long string, escaped once in the middle');

my $obj = bless {}, 'Punk::EscapeTest';
{ package Punk::EscapeTest; use overload '""' => sub { '<obj>' }, fallback => 1; }
is(esc($obj), '&lt;obj&gt;', 'an object escapes its string form');

ok(!defined &Punk::escape_html, 'it is a context method, not a Punk function');

done_testing;
