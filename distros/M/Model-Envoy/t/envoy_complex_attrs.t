package My::CanStringify;

use Moose;

has 'name' => ( isa => 'Str', is => 'rw' );

sub stringify {
    my ( $self ) = @_;

    return $self->name;
}

1;

package My::CanToString;

use Moose;

has 'name' => ( isa => 'Str', is => 'rw' );

sub to_string {
    my ( $self ) = @_;

    return $self->name;
}

1;

package My::CanToStr;

use Moose;

has 'name' => ( isa => 'Str', is => 'rw' );

sub to_str {
    my ( $self ) = @_;

    return $self->name;
}

1;

package My::CanAsString;

use Moose;

has 'name' => ( isa => 'Str', is => 'rw' );

sub as_string {
    my ( $self ) = @_;

    return $self->name;
}

1;

package My::NoStringify;

use Moose;

has 'name' => ( isa => 'Str', is => 'rw' );

1;

package My::Envoy::ComplexAttrs;

use Moose;

with 'Model::Envoy' => { storage => { } };

has 'id' => (
    is => 'ro',
    isa => 'Num',
    traits => ['Envoy'],
);

has 'can_stringify' => (
    is => 'rw',
    isa => 'My::CanStringify',
    traits => ['Envoy'],
);

has 'can_to_string' => (
    is => 'rw',
    isa => 'My::CanToString',
    traits => ['Envoy'],
);

has 'can_as_string' => (
    is => 'rw',
    isa => 'My::CanAsString',
    traits => ['Envoy'],
);

has 'can_to_str' => (
    is => 'rw',
    isa => 'My::CanToStr',
    traits => ['Envoy'],
);

has 'no_stringify' => (
    is => 'rw',
    isa => 'My::NoStringify',
    traits => ['Envoy'],
);

1;

package main;

use Test::More;

my $test = My::Envoy::ComplexAttrs->new({
    id => 1,
    can_stringify => My::CanStringify->new({ name => 'stringify' } ),
    can_to_string => My::CanToString->new({  name => 'to_string' } ),
    can_to_str    => My::CanToStr->new({     name => 'to_str'    } ),
    can_as_string => My::CanAsString->new({  name => 'as_string' } ),
    no_stringify  => My::NoStringify->new({  name => 'no_string' } ),
});

is( $test->id, 1 );
is( $test->can_stringify->name, 'stringify' );
is( $test->can_to_string->name, 'to_string' );
is( $test->can_to_str->name,    'to_str'    );
is( $test->can_as_string->name, 'as_string' );
is( $test->no_stringify->name,  'no_string' );

my $dump = $test->dump;

is( $dump->{id}, 1 );
is( $dump->{can_stringify}, 'stringify' );
is( $dump->{can_to_string}, 'to_string' );
is( $dump->{can_to_str},    'to_str'    );
is( $dump->{can_as_string}, 'as_string' );
is( $dump->{no_stringify},  undef );

done_testing;
