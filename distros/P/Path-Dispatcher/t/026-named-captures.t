use strict;
use warnings;
use Test::More;
BEGIN {
    if ($] <= 5.010001) {
        plan skip_all => 'This test requires Perl 5.10.1';
    }
}
use Path::Dispatcher;

my $dispatcher = Path::Dispatcher->new(
    rules => [
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^(\w+) (?<second>\w+) (?<third>\w+)?$/,
            block => sub { shift },
        ),
    ],
);

my $match = $dispatcher->run("positional named ");
is_deeply($match->positional_captures, ["positional", "named", undef]);
is_deeply($match->named_captures, { second => "named" });

$match = $dispatcher->run("positional firstnamed secondnamed");
is_deeply($match->positional_captures, ["positional", "firstnamed", "secondnamed"]);
is_deeply($match->named_captures, { second => "firstnamed", third => "secondnamed" });

done_testing;

