use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Tokens->new(
        tokens => ['foo', 'bar'],
        block  => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('foo bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "correctly populated number vars from [str, str] token rule");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Tokens->new(
        tokens => ['foo', qr/bar/],
        block  => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('foo bar');
is_deeply([splice @calls], [ ['foo', 'bar'] ], "ran the first [str, str] rule");

$dispatcher->run('foo barbaz');
is_deeply([splice @calls], [ ['foo', 'barbaz'] ], "ran the second [str, regex] rule");

$dispatcher->run('foo bar baz');
is_deeply([splice @calls], [], "no matches");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Tokens->new(
        tokens => [["Bat", "Super"], "Man"],
        block  => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('Super Man');
is_deeply([splice @calls], [ ['Super', 'Man'] ], "ran the [ [Str,Str], Str ] rule");

$dispatcher->run('Bat Man');
is_deeply([splice @calls], [ ['Bat', 'Man'] ], "ran the [ [Str,Str], Str ] rule");

$dispatcher->run('Aqua Man');
is_deeply([splice @calls], [ ], "no match");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Tokens->new(
        tokens => [[[[qr/Deep/]]], "Man"],
        block  => sub { push @calls, shift->positional_captures },
    ),
);

$dispatcher->run('Deep Man');
is_deeply([splice @calls], [ ['Deep', 'Man'] ], "alternations can be arbitrarily deep");

$dispatcher->run('Not Appearing in this Dispatcher Man');
is_deeply([splice @calls], [ ], "no match");

my $rule = Path::Dispatcher::Rule::Tokens->new(
    tokens         => ['path', 'dispatcher'],
    delimiter      => '::',
    prefix         => 1,
    case_sensitive => 0,
);

my $match = $rule->match(Path::Dispatcher::Path->new('Path::Dispatcher::Rule::Tokens'));
is($match->leftover, 'Rule::Tokens');

done_testing;

