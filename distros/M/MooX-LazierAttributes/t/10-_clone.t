use Test::More;

BEGIN {
    eval {
	    require Moo;
        require Type::Tiny;
        1;
    } or do {
        plan skip_all => "Moo or Type::Tiny is not available";
    };
}

require MooX::LazierAttributes;

run_test(
    args => 'one two',
    expected => 'one two',
    name => '_clone a scalar',
);

run_test(
    args => { one => 'two' },
    expected => { one => 'two' },
    name => '_clone a Hash',
);

run_test(
    args => [ qw/one two/ ],
    expected => [ qw/one two/ ],
    name => '_deep_clone a Array',
);

run_obj_test(
    args => (bless { one => 'two' }, 'Thing'),
    isa => 'Thing',
    key => 'one',
    expected => 'two',
    name => '_clone a Array',
);

{
    package Foo::Bar;

    use Moo;

    has one => (
        is => 'rw',
        default => sub { 'Hello World' },
    );
}

run_obj_test(
    args => Foo::Bar->new(),
    isa => 'Foo::Bar',
    key => 'one',
    expected => 'Hello World',
    name => '_clone moo',
    rw => 1,
);


sub run_test {
    my %test = @_;
    return is_deeply( &MooX::LazierAttributes::_clone($test{args}), $test{expected}, "$test{name}");
}

sub run_obj_test {
    my %test = @_;
    
    my $new_obj = &MooX::LazierAttributes::_clone($test{args});
    isa_ok($new_obj, $test{isa});

    if ($test{rw}) {
        $test{args}->one('reference destroyed');
    }

    is($new_obj->{$test{key}}, $test{expected}, "simply check $test{key} is expected $test{expected}");
}

done_testing();
