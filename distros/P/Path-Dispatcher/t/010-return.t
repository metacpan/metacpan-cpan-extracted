use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

# we currently have no defined return strategy :/

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub { "foo" },
    ),
);

is_deeply([$dispatcher->run('foo', 42)], ["foo"]);

my $dispatch = $dispatcher->dispatch('foo');
is_deeply([$dispatch->run(24)], ["foo"]);

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub { "jinkies" },
    ),
);

is_deeply([$dispatcher->run('foo', 42)], ["foo"]);

$dispatch = $dispatcher->dispatch('foo');
is_deeply([$dispatch->run(24)], ["foo"]);

done_testing;

