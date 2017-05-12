use strict;
use Test::More;

package Counter;

use Minions ();

Minions->minionize({
    interface => [qw(next)],
    implementation => 'Counter::Impl',
});

package Counter::Impl;

use Minions::Implementation
    has  => {
        count => { default => 0 },
    } 
;

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

package main;

my $counter = Counter->new;

is($counter->next, 0);
is($counter->next, 1);
is($counter->next, 2);
done_testing();
