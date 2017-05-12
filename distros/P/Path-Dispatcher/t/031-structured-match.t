use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my $outer = Path::Dispatcher::Rule::Regex->new(
    regex  => qr/^(\w+) /,
    prefix => 1,
);

my $inner = Path::Dispatcher::Rule::Regex->new(
    regex => qr/^(\w+)/,
    block => sub { return shift }
);

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Under->new(
            predicate => $outer,
            rules     => [ $inner ],
        ),
    ],
);

my $match = $dispatcher->run("hello world");
my $parent = $match->parent;

ok($parent, 'we have a parent too');
ok($match, 'matched');

is($parent->pos(1), 'hello', 'outer capture');
is($match->pos(1), 'world', 'inner capture');

is($parent->rule, $outer, 'outer rule');
is($match->rule, $inner, 'inner rule');

is_deeply($parent->positional_captures, ['hello'], 'all pos captures');
is_deeply($match->positional_captures, ['world'], 'all pos captures');

is($parent->path->path, 'hello world', 'outer path');
is($match->path->path, 'world', 'inner path');

is($parent->leftover, 'world', 'outer leftover');
is($match->leftover, undef, 'no inner leftover');

done_testing;

