use strict;
use warnings;
use Test::More;

{
	package Counter::Role;

	use Moose::Role;

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
    package Counter;

    use Moose;
    with 'Counter::Role';

	__PACKAGE__->meta->make_immutable;
}

{

    package Display;

    use Test::More;

    use Moose;

    with 'MooseX::Observer::Role::Observer';

    sub update {
        my ( $self, $subject, $args, $eventname ) = @_;

		$self->inc_event;

        like $subject->count, qr{^-?\d+$},
            'Observed number ' . $subject->count;
            
        like $eventname, qr{^(?:in|de)c_counter},
            'Observed eventname ' . $eventname;
    }

	has event => (
		traits => ['Counter'],
		is     => 'rw',
		isa    => 'Int',
		default => 0,
		handles => {
			inc_event => 'inc',
		},
	);
}

my $count = new_ok( 'Counter' );

$count->add_observer( my $display = Display->new );

is( $count->count_observers, 1, 'Only one observer' );
is( $count->count, 0, 'Default to zero' );

$count->inc_counter;

is( $count->count, 1, 'Increment to one ' );

is( $display->event, 1 , 'event recorded');

done_testing;
