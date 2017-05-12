use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub {
            my $match = shift;
            push @calls, [@_];
        },
    ),
);

is_deeply([splice @calls], [], "no calls to the rule block yet");

my $dispatch = $dispatcher->dispatch('foo');
is_deeply([splice @calls], [], "no calls to the rule block yet");

isa_ok($dispatch, 'Path::Dispatcher::Dispatch');
$dispatch->run;
is_deeply([splice @calls], [ [] ], "finally invoked the rule block");

$dispatcher->run('foo');
is_deeply([splice @calls], [ [] ], "invoked the rule block on 'run'");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/(bar)/,
        block => sub {
            my $match = shift;
            push @calls, $match->positional_captures;
        },
    ),
);

is_deeply([splice @calls], [], "no calls to the rule block yet");

$dispatch = $dispatcher->dispatch('bar');
is_deeply([splice @calls], [], "no calls to the rule block yet");

isa_ok($dispatch, 'Path::Dispatcher::Dispatch');
$dispatch->run;
is_deeply([splice @calls], [ ['bar'] ], "finally invoked the rule block");

$dispatcher->run('bar');
is_deeply([splice @calls], [ ['bar'] ], "invoked the rule block on 'run'");

isa_ok($dispatch, 'Path::Dispatcher::Dispatch');
$dispatch->run;
is_deeply([splice @calls], [ ['bar'] ], "invoked the rule block on 'run', makes sure ->pos etc are still correctly set");

done_testing;
