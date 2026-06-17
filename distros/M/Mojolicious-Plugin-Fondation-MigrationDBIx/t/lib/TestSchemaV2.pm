package TestSchemaV2;

use base 'DBIx::Class::Schema';

our $VERSION = '2';

__PACKAGE__->load_classes({ 'TestSchemaV2::Result' => ['FooV2'] });

1;
