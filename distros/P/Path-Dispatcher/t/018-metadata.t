use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Metadata->new(
            field   => "http_method",
            matcher => Path::Dispatcher::Rule::Eq->new(string => "GET"),
            block   => sub { push @calls, $_ },
        ),
    ],
);

$dispatcher->run(Path::Dispatcher::Path->new(
    path     => "the path",
    metadata => {
        http_method => "GET",
    },
));

is_deeply([splice @calls], ["the path"]);

$dispatcher->run(Path::Dispatcher::Path->new(
    path     => "the path",
    metadata => {
        http_method => "POST",
    },
));

is_deeply([splice @calls], [], "metadata didn't match");

done_testing;
