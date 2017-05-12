package SharedTests;

use strict;
use warnings;

use Scalar::Util qw( isweak );
use Test::More;

use vars qw($Lazy);

our %Attrs = (
    ObjectCount => {
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    },
    WeakAttribute => {
        is       => 'rw',
        isa      => 'Object',
        weak_ref => 1,
    },
    LazyAttribute => {
        is   => 'rw',
        isa  => 'Int',
        lazy => 1,

        # The side effect is used to test that this was called
        # lazily.
        default => sub { $Lazy = 1 },
    },
    ReadOnlyAttribute => {
        is      => 'ro',
        isa     => 'Int',
        default => 10,
    },
    ManyNames => {
        is        => 'rw',
        isa       => 'Int',
        reader    => 'M',
        writer    => 'SetM',
        clearer   => 'ClearM',
        predicate => 'HasM',
    },
    Delegatee => {
        is      => 'rw',
        isa     => 'Delegatee',
        handles => [ 'units', 'color' ],

        # if it's not lazy it makes a new object before we define
        # Delegatee's attributes.
        lazy    => 1,
        default => sub { Delegatee->new() },
    },
    Mapping => {
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRef[Str]',
        default => sub { {} },
        handles => {
            'ExistsInMapping' => 'exists',
            'IdsInMapping'    => 'keys',
            'GetMapping'      => 'get',
            'SetMapping'      => 'set',
        },
    },
    Built => {
        is      => 'ro',
        builder => '_BuildIt',
    },
    LazyBuilt => {
        is      => 'ro',
        lazy    => 1,
        builder => '_BuildIt',
    },
    Triggerish => {
        is      => 'rw',
        trigger => sub { shift->_CallTrigger(@_) },
    },
    TriggerRecord => {
        is      => 'ro',
        default => sub { [] },
    },
);

{
    package HasClassAttribute;

    use Moose qw( has );
    use MooseX::ClassAttribute;

    while ( my ( $name, $def ) = each %SharedTests::Attrs ) {
        class_has $name => %{$def};
    }

    has 'size' => (
        is      => 'rw',
        isa     => 'Int',
        default => 5,
    );

    no Moose;

    sub BUILD {
        my $self = shift;

        $self->ObjectCount( $self->ObjectCount() + 1 );
    }

    sub _BuildIt {42}

    sub _CallTrigger {
        push @{ $_[0]->TriggerRecord() }, [@_];
    }

    sub make_immutable {
        my $class = shift;

        $class->meta()->make_immutable();
        Delegatee->meta()->make_immutable();
    }
}

{
    package Delegatee;

    use Moose;

    has 'units' => (
        is      => 'ro',
        default => 5,
    );

    has 'color' => (
        is      => 'ro',
        default => 'blue',
    );

    no Moose;
}

{
    package Child;

    use Moose;
    use MooseX::ClassAttribute;

    extends 'HasClassAttribute';

    class_has '+ReadOnlyAttribute' => ( default => 30 );

    class_has 'YetAnotherAttribute' => (
        is      => 'ro',
        default => 'thing',
    );

    no Moose;
}

sub run_tests {
    my $thing = shift || 'HasClassAttribute';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $Lazy = 0;

    my $count = ref $thing ? 1 : 0;

    {
        is(
            $thing->ObjectCount(), $count,
            'ObjectCount() is 0'
        );

        unless ( ref $thing ) {
            my $hca1 = $thing->new();
            is(
                $hca1->size(), 5,
                'size is 5 - object attribute works as expected'
            );
            is(
                $thing->ObjectCount(), 1,
                'ObjectCount() is 1'
            );

            my $hca2 = $thing->new( size => 10 );
            is(
                $hca2->size(), 10,
                'size is 10 - object attribute can be set via constructor'
            );
            is(
                $thing->ObjectCount(), 2,
                'ObjectCount() is 2'
            );
            is(
                $hca2->ObjectCount(), 2,
                'ObjectCount() is 2 - can call class attribute accessor on object'
            );
        }
    }

    unless ( ref $thing ) {
        my $hca3 = $thing->new( ObjectCount => 20 );
        is(
            $hca3->ObjectCount(), 3,
            'class attributes passed to the constructor do not get set in the object'
        );
        is(
            $thing->ObjectCount(), 3,
            'class attributes are not affected by constructor params'
        );
    }

    {
        my $object = bless {}, 'Thing';

        $thing->WeakAttribute($object);

        undef $object;

        ok(
            !defined $thing->WeakAttribute(),
            'weak class attributes are weak'
        );
    }

    {
        is(
            $SharedTests::Lazy, 0,
            '$SharedTests::Lazy is 0'
        );

        is(
            $thing->LazyAttribute(), 1,
            '$thing->LazyAttribute() is 1'
        );

        is(
            $SharedTests::Lazy, 1,
            '$SharedTests::Lazy is 1 after calling LazyAttribute'
        );
    }

    {
        eval { $thing->ReadOnlyAttribute(20) };
        like(
            $@, qr/\QCannot assign a value to a read-only accessor/,
            'cannot set read-only class attribute'
        );
    }

    {
        is(
            Child->ReadOnlyAttribute(), 30,
            q{Child class can extend parent's class attribute}
        );
    }

    {
        ok(
            !$thing->HasM(),
            'HasM() returns false before M is set'
        );

        $thing->SetM(22);

        ok(
            $thing->HasM(),
            'HasM() returns true after M is set'
        );
        is(
            $thing->M(), 22,
            'M() returns 22'
        );

        $thing->ClearM();

        ok(
            !$thing->HasM(),
            'HasM() returns false after M is cleared'
        );
    }

    {
        isa_ok(
            $thing->Delegatee(), 'Delegatee',
            'has a Delegetee object'
        );
        is(
            $thing->units(), 5,
            'units() delegates to Delegatee and returns 5'
        );
    }

    {
        my @ids = $thing->IdsInMapping();
        is(
            scalar @ids, 0,
            'there are no keys in the mapping yet'
        );

        ok(
            !$thing->ExistsInMapping('a'),
            'key does not exist in mapping'
        );

        $thing->SetMapping( a => 20 );

        ok(
            $thing->ExistsInMapping('a'),
            'key does exist in mapping'
        );

        is(
            $thing->GetMapping('a'), 20,
            'value for a in mapping is 20'
        );
    }

    {
        is(
            $thing->Built(), 42,
            'attribute with builder works'
        );

        is(
            $thing->LazyBuilt(), 42,
            'attribute with lazy builder works'
        );
    }

    {
        $thing->Triggerish(42);

        is( scalar @{ $thing->TriggerRecord() }, 1,  'trigger was called' );
        is( $thing->Triggerish(),                42, 'Triggerish is now 42' );

        $thing->Triggerish(84);
        is( $thing->Triggerish(), 84, 'Triggerish is now 84' );

        is_deeply(
            $thing->TriggerRecord(),
            [
                [ $thing, qw( 42 ) ],
                [ $thing, qw( 84 42 ) ],
            ],
            'trigger passes old value correctly'
        );
    }
}

1;
