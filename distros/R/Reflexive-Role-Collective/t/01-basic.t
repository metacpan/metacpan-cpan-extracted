use warnings;
use strict;
use Test::More;

my $forgets = 0;
my $remembers = 0;
my $reemits = 0;
{
    package MyCollection;
    use Moose;
    use Moose::Util::TypeConstraints;
    with 'Reflex::Role::Reactive';

    has store => (
        is      => 'rw',
        isa     => 'HashRef',
        traits  => ['Hash'],
        default => sub { {} },
        clearer => 'clear_objects',
        handles => {
            add_object => 'set',
            del_object => 'delete',
            count_objects => 'count',
        },
    );

    with 'Reflexive::Role::Collective' =>
    {
        stored_constraint => role_type('Reflex::Role::Collectible'),
        watched_events => [ [ stopped => 'forget_me' ], [ foo_event => [ 'foo_method' => 'foo_reemit' ] ] ],
        method_clear_objects => 'clear_objects',
        method_count_objects => 'count_objects',
        method_add_object => 'add_object',
        method_del_object => 'del_object',
    };

    sub forget_me
    {
        my ($self, $event) = @_;
        Test::More::pass('got forget_me. total forgets: ' . ++$forgets);
        $self->forget($event->get_first_emitter());
    }

    around remember => sub
    {
        my ($orig, $self, $obj) = @_;
        Test::More::pass('got remember. total remembers: ' . ++$remembers);
        $self->$orig($obj);
    };
}

{
    package MyCollectible;
    use Moose;
    with 'Reflex::Role::Reactive';
    with 'Reflex::Role::Collectible';

    sub foo { shift->emit(-name => 'foo_event') }
}

{
    package CollectionTester;
    use Moose;
    with 'Reflex::Role::Reactive';

    has collection =>
    (
        is => 'rw',
        isa => 'MyCollection',
        traits => ['Reflex::Trait::Watched'],
        handles => ['remember', 'count_objects'],
        setup => {},
    );

    sub on_collection_foo_reemit
    {
        $reemits++;
        Test::More::pass('foo emitted from a collectible, caught in a collection, and reemitted and caught by the tester');
    }
}

my $tester = CollectionTester->new();
my $collectibles = [];
for(0..9)
{
    push(@$collectibles, MyCollectible->new());
    $tester->remember($collectibles->[$_]);
}

($_->foo, $_->stopped()) for @$collectibles;

$tester->run_all();

is($forgets, $remembers, 'got the same amount of forgets and remembers');
is($tester->count_objects, 0, 'No more objects in the collection');
is($reemits, $forgets, 'got the right amount of reemits');

done_testing();
