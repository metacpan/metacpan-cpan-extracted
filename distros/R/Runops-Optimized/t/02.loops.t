use Test::More;
use Attribute::Handlers;
use Runops::Optimized;

sub T :ATTR(CODE) {
    push @tests, [$_[1], $_[2]];
}

sub basicgrep :T {
    scalar grep { $_ % 2 } 1 .. 2;
}

sub basicmap :T {
    use List::Util qw(sum);
    sum map +($_, $_ * 2), 1 .. 10;
}

for(@tests) {
    is $_->[1]->(), $_->[1]->(), *{$_->[0]};
}

done_testing;
