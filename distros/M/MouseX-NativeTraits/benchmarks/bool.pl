#!perl -w

use strict;
use Benchmark qw(:all);

print "Benchmark for native traits (Bool)\n";

{
    package MouseBool;
    use Mouse;

    has ok => (
        is  => 'rw',
        isa => 'Bool',

        traits => ['Bool'],

        handles => {
            toggle => 'toggle',
        },
        default => 0,
    );

    __PACKAGE__->meta->make_immutable();
}

{
    package MooseBool;
    use Moose;

    has ok => (
        is  => 'rw',
        isa => 'Bool',

        traits => ['Bool'],

        handles => {
            toggle => 'toggle',
        },
        default => 0,
    );

    __PACKAGE__->meta->make_immutable();
}

my $mouse = MouseBool->new;
my $moose = MooseBool->new;

print "toggle && ok\n";
cmpthese -1 => {
    Mouse => sub{
        $mouse->toggle();
        $mouse->ok && $mouse->ok && $mouse->ok;
    },
    Moose => sub{
        $moose->toggle();
        $moose->ok && $moose->ok && $moose->ok;
    },
};
