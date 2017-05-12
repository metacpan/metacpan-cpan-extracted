use Test::More;

BEGIN {
    eval {
        require Type::Tiny;
        1;
    } or do {
        plan skip_all => "cannot require Type::Tiny";
    };
}

require MooX::LazierAttributes;

use Types::Standard qw/Str ArrayRef HashRef/;

run_test(
    args => [ 'ro' ],
    expected => {
		is => 'ro',
	},
    name => 'construct_attributes a ro attribute' ,
);

run_test(
    args => [ 'rw', ],
    expected => {
		is => 'rw',
	},
    name => 'construct_attributes a rw attribute' ,
);

run_test(
    args => ['rw', undef, { 'builder' => 1, } ],
    expected => {
		is => 'rw',
		builder => 1,
	},
    name => 'construct_attributes a rw attribute with a builder',
);

run_test(
    args => ['ro', undef, { required => 1 } ],
    expected => {
		is => 'ro', 
		required => 1,
	},
    name => 'construct_attributes a ro attribute that is required',
);

run_test_default( 
    args => ['ro', 'Hello World' ],
    expected => 'Hello World',
    name => 'construct_attributes a ro attribute that is required',
);

run_test_default( 
    args => ['ro', sub { 'Hello World' } ],
    expected => 'Hello World',
    name => 'construct_attributes a ro attribute that is required',
);

run_test_isa( 
    args => ['ro', Str, { default => sub { 'Hello World' } } ],
    expected => 'Hello World',
    name => 'construct_attributes with a Type::Tiny Isa',
);

run_test_isa( 
    args => ['ro', HashRef, ],
    expected => 'Hello World',
    name => 'construct_attributes with a Type::Tiny Isa',
);

run_test_isa( 
    args => ['ro', [qw/one two three/], { isa => ArrayRef }],
    expected => 'Hello World',
    name => 'construct_attributes with a Type::Tiny Isa',
);

sub run_test {
    my %test = @_;
    return is_deeply( {&MooX::LazierAttributes::construct_attribute(@{ $test{args} })}, $test{expected}, "$test{name}");
}

sub run_test_default {
    my %test = @_;
    my %attr = &MooX::LazierAttributes::construct_attribute(@{ $test{args} });
    return is( $attr{default}->(), $test{expected}, "$test{name}");
}

sub run_test_isa {
    my %test = @_;
    my %attr = &MooX::LazierAttributes::construct_attribute(@{ $test{args} });
    return is( ref $attr{isa}, 'Type::Tiny', "$test{name}");
}

done_testing();
