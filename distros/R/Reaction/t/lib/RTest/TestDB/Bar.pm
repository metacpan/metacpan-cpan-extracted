package # hide from PAUSE
  RTest::TestDB::Bar;

use Moose;
extends 'DBIx::Class';

use aliased 'RTest::TestDB::Foo';
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::DateTime qw/DateTime/;
use Reaction::Types::File 'File';

has 'name' => (isa => NonEmptySimpleStr, is => 'rw', required => 1);
has 'foo' => (isa => Foo, is => 'rw', required => 1);
has 'published_at' => (isa => DateTime, is => 'rw');
has 'avatar' => (isa => File, is => 'rw');

use namespace::clean -except => [ 'meta' ];

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);

__PACKAGE__->table('bar');

__PACKAGE__->add_columns(
  name => { data_type => 'varchar', size => 255 },
  foo_id => { data_type => 'integer', size => 16 },
  published_at => { data_type => 'datetime', is_nullable => 1 },
  avatar => { data_type => 'blob', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('name');

__PACKAGE__->belongs_to(
  'foo' => Foo,
  { 'foreign.id' => 'self.foo_id' }
);

sub display_name{ shift->name }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
