use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^foobar/,
            block => sub { "foobar matched" },
        ),
    ],
);

my $result = $dispatcher->run("foobar");
is($result, "foobar matched");

$dispatcher->add_rule(
    Path::Dispatcher::Rule::Regex->new(
        regex => qr/^foo/,
        block => sub { "foo matched" },
    ),
);

$result = $dispatcher->run("foobar");
is($result, "foobar matched");

my $dispatch = $dispatcher->dispatch("foobar");
$result = $dispatch->run("foobar");
is($result, "foobar matched");

my @results = $dispatch->run("foobar");
is_deeply(\@results, ["foobar matched"]);

done_testing;

