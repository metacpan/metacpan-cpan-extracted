package ComponentUI::TestModel;

use lib 't/lib';
use base 'Reaction::InterfaceModel::Object';
use Reaction::Class;
use Reaction::InterfaceModel::Reflector::DBIC;

my $reflector = Reaction::InterfaceModel::Reflector::DBIC->new;

$reflector->reflect_schema(
  model_class  => __PACKAGE__,
  schema_class => 'RTest::TestDB',
  sources => [
    qw/Foo Baz/,
    [ Bar => {attributes => [[-exclude => 'avatar']] } ], ## for now....
  ],
);

__PACKAGE__->meta->make_immutable;

1;

__END__;
