use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Under->new(
            predicate => Path::Dispatcher::Rule::Tokens->new(
                tokens => ['show'],
                prefix => 1,
            ),
            rules => [
                Path::Dispatcher::Rule::Chain->new(
                    block => sub { push @calls, 'chain' },
                ),
                Path::Dispatcher::Rule::Tokens->new(
                    tokens => ['inventory'],
                    block  => sub { push @calls, 'inventory' },
                ),
                Path::Dispatcher::Rule::Tokens->new(
                    tokens => ['score'],
                    block  => sub { push @calls, 'score' },
                ),
            ],
        ),
    ],
);

$dispatcher->run("show inventory");
is_deeply([splice @calls], [ 'chain', 'inventory' ]);

$dispatcher->run("show score");
is_deeply([splice @calls], [ 'chain', 'score' ]);

$dispatcher->run("show nothing");
is_deeply([splice @calls], [ ]);

$dispatcher->run("do nothing");
is_deeply([splice @calls], [ ]);

$dispatcher->run("do inventory");
is_deeply([splice @calls], [ ]);

$dispatcher->run("do score");
is_deeply([splice @calls], [ ]);

done_testing;

