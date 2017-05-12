use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my $match;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^(\w+) (Q)(Q) (\w+)$/,
            block => sub {
                $match = shift;
            },
        ),
    ],
);

$dispatcher->run("chewy QQ cute");
is_deeply($match->positional_captures, ["chewy", "Q", "Q", "cute"]);
is_deeply($match->pos(1), "chewy");
is_deeply($match->pos(2), "Q");
is_deeply($match->pos(3), "Q");
is_deeply($match->pos(4), "cute");

is_deeply($match->pos(0), undef);
is_deeply($match->pos(5), undef);

is_deeply($match->pos(-1), "cute");

done_testing;

