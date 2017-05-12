use strict;
use warnings;
use Test::More;
use Path::Dispatcher;

my @recaptures;
my $rule = Path::Dispatcher::Rule::Regex->new(
    regex => qr/^(foo)(bar)?(baz)$/,
    block => sub {
        push @recaptures, @{ shift->positional_captures };
    },
);

my $match = $rule->match(Path::Dispatcher::Path->new("foobaz"));
is_deeply($match->positional_captures, ['foo', undef, 'baz']);

$match->run;
is_deeply(\@recaptures, ['foo', undef, 'baz']);

done_testing;

