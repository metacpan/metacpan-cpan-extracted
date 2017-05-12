use strict;
use warnings;

{
    package Counter;

    use Moose;

    has count => (
        traits  => ['Counter'],
        is      => 'ro',
        isa     => 'Int',
        default => 0,
        handles => {
            inc_counter => 'inc',
            dec_counter => 'dec',
        },
    );

    with 'MooseX::Observer::Role::Observable' => { notify_after => [qw~
        inc_counter
        dec_counter
        test_after_role
    ~] };

    sub test_after_role {}
}

{

    package Display;

    use Test::More;

    use Moose;

    with 'MooseX::Observer::Role::Observer';

    sub update {
        my ( $self, $subject, $args, $eventname ) = @_;
        like $subject->count, qr{^-?\d+$},
            'Observed number ' . $subject->count;
            
        like $eventname, qr{^(?:in|de)c_counter},
            'Observed eventname ' . $eventname;
    }
}

package main;

use Test::More tests => 44;

my $count = Counter->new();

ok( $count->can('add_observer'), 'add_observer method added' );

ok( $count->can('count_observers'), 'count_observers method added' );

ok( $count->can('inc_counter'), 'inc_counter method added' );

ok( $count->can('dec_counter'), 'dec_counter method added' );

$count->add_observer( Display->new() );

is( $count->count_observers, 1, 'Only one observer' );

is( $count->count, 0, 'Default to zero' );

$count->inc_counter;

is( $count->count, 1, 'Increment to one ' );

$count->inc_counter for ( 1 .. 6 );

is( $count->count, 7, 'Increment up to seven' );

$count->dec_counter;

is( $count->count, 6, 'Decrement to 6' );

$count->dec_counter for ( 1 .. 5 );

is( $count->count, 1, 'Decrement to 1' );

$count->dec_counter for ( 1 .. 2 );

is( $count->count, -1, 'Negative numbers' );

$count->inc_counter;

is( $count->count, 0, 'Back to zero' );