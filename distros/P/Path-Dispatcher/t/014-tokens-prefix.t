use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my $rule = Path::Dispatcher::Rule::Tokens->new(
    tokens => ['foo', 'bar'],
    block  => sub { },
    prefix => 1,
);

ok(!$rule->match(Path::Dispatcher::Path->new('foo')), "prefix means the rule matches a prefix of the path, not the other way around");
ok($rule->match(Path::Dispatcher::Path->new('foo bar')), "prefix matches the full path");

my $match = $rule->match(Path::Dispatcher::Path->new('foo bar baz'));
ok($match, "prefix matches a prefix of the path");
is_deeply($match->positional_captures, ["foo", "bar"]);
is($match->leftover, "baz");

done_testing;

