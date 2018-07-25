package My::Envoy::Widget;

    use Moose;

    extends 'My::Envoy';

    has 'id' => (
        is => 'ro',
        isa => 'Num',
    );

    has 'name' => (
        is => 'rw',
        isa => 'Maybe[Str]',
    );

1;