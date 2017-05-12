use strict;
use warnings;
use Test::More;
use Path::Dispatcher::Rule;

my @calls;

my $rule = Path::Dispatcher::Rule::Regex->new(
    regex => qr/^(..)(..)/,
    block => sub {
        push @calls, {
            vars => [$1, $2, $3],
            args => [@_],
        }
    },
);

my $match = $rule->match(Path::Dispatcher::Path->new('foobar'));
isa_ok($match, 'Path::Dispatcher::Match');
is_deeply($match->positional_captures, ['fo', 'ob']);
is_deeply([splice @calls], [], "block not called on match");

$rule->run;
is_deeply([splice @calls], [{
    vars => [undef, undef, undef],
    args => [],
}], "block called on ->run");

done_testing;

