use Test::More tests => 11;

do {
    package Counter;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'value' => (
        metaclass => 'Counter',
        is        => 'rw',
        isa       => 'Int',
        default   => sub { 0 },
        provides  => { inc => 'inc' },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;

    package Number;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'value' => (
        metaclass => 'Number',
        is        => 'rw',
        isa       => 'Int',
        default   => sub { 5 },
        provides  => { add => 'add' },
        curries   => { add => { inc => [ 1 ] } },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;

    package String;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'value' => (
        metaclass => 'String',
        is        => 'rw',
        isa       => 'Str',
        default   => sub { '' },
        provides  => { append => 'append' },
        curries   => { append => { exclaim => [ '!' ] } },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;

    package Bool;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'has_value' => (
        metaclass => 'Bool',
        is        => 'rw',
        isa       => 'Bool',
        default   => sub { 0 },
        provides  => { toggle => 'toggle' },
    );

    no Mouse;
    __PACKAGE__->meta->make_immutable;
};

my $counter = Counter->new;
is $counter->value => 0, 'counter default ok';
$counter->inc;
is $counter->value => 1, 'counter inc ok';

my $number = Number->new;
is $number->value => 5, 'number default ok';
$number->add(10);
is $number->value => 15, 'number add ok';
$number->inc;
is $number->value => 16, 'number curry(inc) ok';

my $string = String->new;
is $string->value => '', 'string default ok';
$string->append('foobar');
is $string->value => 'foobar', 'string append ok';
$string->exclaim;
is $string->value => 'foobar!', 'string curry(append) ok';

my $bool = Bool->new;
ok !$bool->has_value, 'bool default ok';
$bool->toggle;
ok $bool->has_value, 'bool toggle ok';
$bool->toggle;
ok !$bool->has_value, 'bool toggle again ok';
