use strict;
use Test::More;
use Minions ();

package Counter::Impl;

our %__meta__ = (
    has  => {
        count => { default => 0 },
    }, 
);

sub next {
    my ($self) = @_;

    $self->{-count}++;
}

package Counter;

our %__meta__ = (
    interface => [qw(next)],
    implementation => 'Counter::Impl',
);
Minions->minionize;

package main;

my $counter = Counter->new;

is($counter->next, 0);
is($counter->next, 1);
is($counter->next, 2);
done_testing();
