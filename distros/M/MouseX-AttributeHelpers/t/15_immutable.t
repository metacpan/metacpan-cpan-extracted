use Test::More tests => 10;

do {
    package Standard;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        is        => 'rw',
        isa       => 'Int',
        default   => 0,
        provides  => {
            inc => 'inc_counter',
            dec => 'dec_counter',
        },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;

    package Default;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        provides  => {
            inc => 'inc_counter',
            dec => 'dec_counter',
        },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

for my $class ('Standard', 'Default') {
    my $obj = $class->new;

    for my $provider ('inc_counter', 'dec_counter') {
        can_ok $obj => $provider;
    }

    is $obj->counter => 0, 'get default value ok';

    $obj->inc_counter;
    $obj->inc_counter;
    is $obj->counter => 2, 'increment ok';

    $obj->dec_counter;
    is $obj->counter => 1, 'decrement ok';
}
