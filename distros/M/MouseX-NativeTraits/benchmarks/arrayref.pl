#!perl -w

use strict;
use Benchmark qw(:all);

print "Benchmark for native traits (Array)\n";

{
    package MouseStack;
    use Mouse;

    has stack => (
        is  => 'rw',
        isa => 'ArrayRef',

        traits => ['Array'],

        handles => {
            pop      => 'pop',
            push     => 'push',
            top      => [ get => -1 ],
            is_empty => 'is_empty',
        },
        default => sub{ [] },
    );

    __PACKAGE__->meta->make_immutable();
}

{
    package MooseStack;
    use Moose;

    has stack => (
        is  => 'rw',
        isa => 'ArrayRef',

        traits => ['Array'],

        handles => {
            pop      => 'pop',
            push     => 'push',
            top      => [ get => -1 ],
            is_empty => 'is_empty',
        },
        default => sub{ [] },
    );

    __PACKAGE__->meta->make_immutable();
}

my $mouse = MouseStack->new;
my $moose = MooseStack->new;

print "push && pop && is_empty\n";
cmpthese -1 => {
    Mouse => sub{
        $mouse->push($_) for 1 .. 100;
        $mouse->pop()    until $mouse->is_empty;
    },
    Moose => sub{
        $moose->push($_) for 1 .. 100;
        $moose->pop()    until $moose->is_empty;
    },
};
