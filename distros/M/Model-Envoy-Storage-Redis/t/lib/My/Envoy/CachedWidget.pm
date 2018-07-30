package My::Envoy::CachedWidget;

use Moose;

extends 'My::CachedEnvoy';


has 'id' => (
    is => 'ro',
    isa => 'Num',

);

has 'name' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

1;
