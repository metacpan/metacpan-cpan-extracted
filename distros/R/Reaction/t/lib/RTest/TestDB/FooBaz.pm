package # hide from PAUSE
  RTest::TestDB::FooBaz;

use Moose;
extends 'DBIx::Class::Core';

__PACKAGE__->table('foo_baz');

__PACKAGE__->add_columns(
  foo => { data_type => 'integer', size => 16 },
  baz => { data_type => 'integer', size => 16 },
);

__PACKAGE__->set_primary_key(qw/foo baz/);

__PACKAGE__->belongs_to('foo' => 'RTest::TestDB::Foo');
__PACKAGE__->belongs_to('baz' => 'RTest::TestDB::Baz');

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
