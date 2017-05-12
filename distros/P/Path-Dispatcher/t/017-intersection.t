use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @calls;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Intersection->new(
            rules => [
                Path::Dispatcher::Rule::Tokens->new(
                    tokens => ['foo'],
                    block => sub { push @calls, 'tokens' },
                ),
                Path::Dispatcher::Rule::Regex->new(
                    regex => qr/^foo$/,
                    block => sub { push @calls, 'regex' },
                ),
            ],
            block => sub { push @calls, 'intersection' },
        ),
    ],
);

$dispatcher->run("foo");
is_deeply([splice @calls], ['intersection'], "the intersection matched; doesn't automatically run the subrules");

$dispatcher->run("food");
is_deeply([splice @calls], [], "each subrule of the intersection must match");

$dispatcher->run(" foo ");
is_deeply([splice @calls], [], "each subrule of the intersection must match");

# test empty intersection
$dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Intersection->new(
            rules => [ ],
            block => sub { push @calls, 'intersection' },
        ),
    ],
);

$dispatcher->run("foo");
is_deeply([splice @calls], [], "no subrules means no match");

done_testing;

