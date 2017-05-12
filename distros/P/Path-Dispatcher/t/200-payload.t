use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Regex->new(
            regex   => qr/^(\w+)$/,
            payload => 'all the money',
        ),
    ],
);

my $dispatch = $dispatcher->dispatch('hello');
ok($dispatch->has_matches);

my $match = $dispatch->first_match;
ok($match->rule->isa('Path::Dispatcher::Rule::Regex'));
ok($match->rule->payload, 'all the money');
ok($match->payload, 'all the money');

like(exception {
    $dispatch->run
}, qr/Payload is not a coderef/);

like(exception {
    $dispatcher->run('bye')
}, qr/Payload is not a coderef/);

done_testing;

