use Test::More tests => 18;

{
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        is        => 'rw',
        isa       => 'Int',
        builder   => '_build_counter',
        provides  => { inc => 'inc_counter' },
    );

    has 'string' => (
        metaclass  => 'String',
        is         => 'rw',
        isa        => 'Str',
        lazy_build => 1,
        provides   => { append => 'append_string' },
    );

    has 'bag' => (
        metaclass => 'Collection::Bag',
        is        => 'rw',
        isa       => 'Bag',
        provides  => { add => 'add_bag', count => 'num_bag', get => 'get_bag' },
    );

    sub _build_counter { 100 }
    sub _build_string  { 'MouseX' }

    package MyImmutableClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        is        => 'rw',
        isa       => 'Int',
        builder   => '_build_counter',
        provides  => { inc => 'inc_counter' },
    );

    has 'string' => (
        metaclass  => 'String',
        is         => 'rw',
        isa        => 'Str',
        lazy_build => 1,
        provides   => { append => 'append_string' },
    );

    has 'bag' => (
        metaclass => 'Collection::Bag',
        is        => 'rw',
        isa       => 'Bag',
        provides  => { add => 'add_bag', count => 'num_bag', get => 'get_bag' },
    );

    sub _build_counter { 100 }
    sub _build_string  { 'MouseX' }

    no Mouse;
    __PACKAGE__->meta->make_immutable;
}

for my $class (qw/MyClass MyImmutableClass/) {
    my $obj = $class->new;

    my @providers = qw(inc_counter append_string add_bag);
    for my $method (@providers) {
        can_ok $obj => $method;
    }

    is $obj->counter => 100, 'builder ok';
    $obj->inc_counter(10);
    is $obj->counter => 110, 'inc ok';

    is $obj->string => 'MouseX', 'lazy_build ok';
    $obj->append_string('::AttributeHelpers');
    is $obj->string => 'MouseX::AttributeHelpers', 'append ok';

    $obj->add_bag('mouse') for 1..10;
    is $obj->num_bag => 1, 'count ok';
    is $obj->get_bag('mouse') => 10, 'get ok';
}
