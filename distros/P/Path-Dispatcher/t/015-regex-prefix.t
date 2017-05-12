use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $rule = Path::Dispatcher::Rule::Regex->new(
    regex  => qr/^(foo)\s*(bar)/,
    block  => sub { push @calls, [$1, $2] },
    prefix => 1,
);

ok(!$rule->match(Path::Dispatcher::Path->new('foo')), "prefix means the rule matches a prefix of the path, not the other way around");
ok($rule->match(Path::Dispatcher::Path->new('foo bar')), "prefix matches the full path");
ok($rule->match(Path::Dispatcher::Path->new('foo bar baz')), "prefix matches a prefix of the path");
my $match = $rule->match(Path::Dispatcher::Path->new('foobar:baz'));

ok($match, "matched foobar:baz");

is_deeply($match->positional_captures, ["foo", "bar"], "match returns just the results");
is($match->leftover, ':baz', "leftovers");

done_testing;

