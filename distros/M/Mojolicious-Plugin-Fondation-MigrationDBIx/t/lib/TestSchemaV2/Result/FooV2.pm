package TestSchemaV2::Result::FooV2;

use base 'DBIx::Class::Core';

__PACKAGE__->table('foos');

__PACKAGE__->add_columns(
    id          => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name        => { data_type => 'varchar', size => 100, is_nullable => 0 },
    description => { data_type => 'varchar', size => 255, is_nullable => 1 },
);

__PACKAGE__->set_primary_key('id');

1;
