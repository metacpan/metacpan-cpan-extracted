use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub { push @calls, [@_] },
    ),
);

my $dispatch = $dispatcher->dispatch('bar');
is_deeply([splice @calls], [], "no calls to the rule block yet");

isa_ok($dispatch, 'Path::Dispatcher::Dispatch');
is($dispatch->matches, 0, "no matches");

$dispatch->run;
is_deeply([splice @calls], [], "no calls to the rule block");

done_testing;

