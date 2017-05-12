use Test::More;


package Thing {
    use Moose;

    use MoobX;

    our $stuff :Observable = 'apple';

    has foo => (
        is => 'rw',
        traits => [ 'Observable' ],
    );

    has bar => (
        is => 'ro',
        traits => [ 'Observer' ],
        lazy => 1,
        default => sub {
            my $self = shift;
            $::bar_counter++;
            $self->foo x  2
        },
    );

    has baz => (
        is => 'ro',
        traits => [ 'Observer' ],
        lazy   => 0,
        default => sub {
            my $self = shift;
            $::baz_counter++;
            $stuff .'!'
        },
    );
};

my $thing = Thing->new( foo => 'a' );

is $thing->bar => 'aa';
is $::bar_counter => 1;
is $::baz_counter => 1;
is $thing->baz => 'apple!';

$thing->foo('b');

is $::bar_counter => 1, 'changed, but not recomputed';

$Thing::stuff = 'banana';
is $::baz_counter => 2, 'reset and recomputed';

$Thing::stuff = 'coconut';
is $::baz_counter => 3, 'reset and recomputed';

is $thing->bar => 'bb', 'recomputed';
is $thing->baz => 'coconut!', 'recomputed';
is $::bar_counter => 2, 'changed, but not recomputed';
is $::baz_counter => 3, 'reset and recomputed';

done_testing;
