use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub { my $match = shift; push @calls, [@_] },
    ),
);

$dispatcher->run('foo', 42);

is_deeply([splice @calls], [
    [42],
]);

my $dispatch = $dispatcher->dispatch('foo');
$dispatch->run(24);

is_deeply([splice @calls], [
    [24],
]);

done_testing;

