#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use Serengeti;

my $browser = Serengeti->new();

my $cx = $browser->context;

my $stash = $browser->session->stash;
is_deeply($stash, {});

throws_ok {
    $cx->match("foo", qr/bar/, { strict => 1 });
} qr/Match matches 0 time\(s\) instead of required 1 time\(s\)/;

lives_ok {
    $cx->match("foo", qr/foo/, { strict => 1 });
};

is_deeply($stash, {});

my $matches = $cx->match("foobar", qr/(foo)(bar)/, { set => "a, b" });
is_deeply($stash, { a => "foo", b => "bar" });
is($matches, 1);

my $root = HTML::TreeBuilder->new_from_content(<<'__END_OF_HTML__');
<html>
<body>
  <h3>Test</h3>
  Foobar
</body>
</html>
__END_OF_HTML__
$root->eof;

$matches = 0;
lives_ok {
    $matches = $cx->match($root->look_down("_tag", "body"), qr/h3>Test/, { strict => 1 });
};

is($matches, 1);

