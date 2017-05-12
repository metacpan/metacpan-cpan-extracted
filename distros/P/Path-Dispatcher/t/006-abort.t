use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new;
$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub {
            push @calls, "on";
            die "Path::Dispatcher abort\n";
        },
    ),
);

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/foo/,
        block => sub {
            push @calls, "last";
        },
    ),
);

my $dispatch = $dispatcher->dispatch('foo');
is_deeply([splice @calls], [], "no blocks called yet of course");

$dispatch->run;
is_deeply([splice @calls], ['on'], "correctly aborted the entire dispatch");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/bar/,
        block => sub {
            push @calls, "bar: before";
            my $x = {}->();
            push @calls, "bar: last";
        },
    ),
);

like(exception {
    $dispatcher->run('bar');
}, qr/Not a CODE reference/);

is_deeply([splice @calls], ['bar: before'], "regular dies pass through");

done_testing;

