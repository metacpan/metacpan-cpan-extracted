#!perl -w

use strict;
use Benchmark qw(:all);

print "Benchmark for native traits (Counter)\n";

{
    package MouseCounter;
    use Mouse;

    has ok => (
        is  => 'rw',
        isa => 'Int',

        traits => ['Counter'],

        handles => {
            inc2 => [inc => 2 ],
        },
        default => 0,
        clearer => 'foo',
    );

    __PACKAGE__->meta->make_immutable();
}

{
    package MooseCounter;
    use Moose;

    has ok => (
        is  => 'rw',
        isa => 'Int',

        traits => ['Counter'],

        handles => {
            inc2 => [inc => 2 ],
        },
        default => 0,
    );

    __PACKAGE__->meta->make_immutable();
}

print "curried inc\n";
cmpthese -1 => {
    Mouse => sub{
        my $mouse = MouseCounter->new;
        $mouse->inc2() for 1 .. 100;
        $mouse->ok == 200 or die $mouse->ok;
    },
    Moose => sub{
        my $moose = MooseCounter->new;
        $moose->inc2() for 1 .. 100;
        $moose->ok == 200 or die $moose->ok;
    },
};
