use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Always->new(
            block => sub { die "hi gang"; "foobar matched" },
        ),
    ],
);

like(exception {
    $dispatcher->run("foobar");
}, qr/hi gang/);

done_testing;

