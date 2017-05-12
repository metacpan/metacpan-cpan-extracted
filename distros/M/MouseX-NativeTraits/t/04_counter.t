#!perl
use strict;
use Test::More;

my $triggered = 0;
{
    package MyHomePage;
    use Mouse;

    has 'counter' => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter   => 'inc',
            dec_counter   => 'dec',
            reset_counter => 'reset',
        },
    );

    has 'counter_w_trigger' => (
        traits  => ['Counter'],
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter2   => 'inc',
            dec_counter2   => 'dec',
            reset_counter2 => 'reset',
        },
        trigger => sub {
            $triggered++;
        },
    );
    __PACKAGE__->meta->make_immutable();
}

my $o = MyHomePage->new();

$o->inc_counter for 1 .. 42;
is $o->counter, 42;

is $triggered, 0;
$o->inc_counter2 for 1 .. 42;
is $o->counter_w_trigger, 42;
is $triggered, 42;

done_testing;

