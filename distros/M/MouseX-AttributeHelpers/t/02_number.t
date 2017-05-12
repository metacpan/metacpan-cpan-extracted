use Test::More tests => 24;

do {
    package MyClass;
    use Mouse;
    use MouseX::AttributeHelpers;

    has 'integer' => (
        metaclass => 'Number',
        is        => 'rw',
        isa       => 'Int',
        default   => 5,
        provides  => {
            set => 'set',
            add => 'add',
            sub => 'sub',
            mul => 'mul',
            div => 'div',
            mod => 'mod',
            abs => 'abs',
        },
        curries   => {
            add => { inc         => [ 1 ] },
            sub => { dec         => [ 1 ] },
            mod => { odd         => [ 2 ] },
            div => { cut_in_half => [ 2 ] },
        },
    );
};

my $obj = MyClass->new;

my @providers = qw(set add sub mul div mod abs);
for my $method (@providers) {
    can_ok $obj => $method;
}

my @curries = qw(inc dec odd cut_in_half);
for my $method (@curries) {
    can_ok $obj => $method;
}

is $obj->integer => 5, 'get default value ok';

# provides
$obj->add(10);
is $obj->integer => 15, 'add ok';

$obj->sub(3);
is $obj->integer => 12, 'subtract ok';

$obj->set(10);
is $obj->integer => 10, 'set value ok';

$obj->div(2);
is $obj->integer => 5, 'divide ok';

$obj->mul(2);
is $obj->integer => 10, 'multiplied ok';

$obj->mod(2);
is $obj->integer => 0, 'mod ok';

$obj->set(7);
$obj->mod(5);
is $obj->integer => 2, 'set and mod ok';

$obj->set(-1);
$obj->abs;
is $obj->integer => 1, 'abs ok';

# curries
$obj->set(12);
$obj->inc;
is $obj->integer => 13, 'curries inc ok';

$obj->dec;
is $obj->integer => 12, 'curries dec ok';

$obj->cut_in_half;
is $obj->integer => 6, 'curries cut_in_half ok';

$obj->odd;
is $obj->integer => 0, 'curries odd ok';
