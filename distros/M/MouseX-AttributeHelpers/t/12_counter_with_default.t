use Test::More tests => 12;

do {
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'counter' => (
        metaclass => 'Counter',
        provides  => {
            inc   => 'inc_counter',
            dec   => 'dec_counter',
            reset => 'reset_counter',
            set   => 'set_counter',
        },
    );
};

my $obj = MyClass->new;

my @providers = qw(inc_counter dec_counter reset_counter set_counter);
for my $provider (@providers) {
    can_ok $obj => $provider;
}

is $obj->counter => 0, 'get default value ok';

$obj->inc_counter;
is $obj->counter => 1, 'increment ok';

$obj->inc_counter;
is $obj->counter => 2, 'increment again ok';

$obj->dec_counter;
is $obj->counter => 1, 'decrement ok';

$obj->reset_counter;
is $obj->counter => 0, 'reset ok';

$obj->set_counter(5);
is $obj->counter => 5, 'set value ok';

$obj->inc_counter(2);
is $obj->counter => 7, 'increment with count ok';

$obj->dec_counter(5);
is $obj->counter => 2, 'decrement with count ok';
