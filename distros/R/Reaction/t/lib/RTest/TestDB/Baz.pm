package # hide from PAUSE
  RTest::TestDB::Baz;

use Moose;
extends 'DBIx::Class::Core';

use MooseX::Types::Moose qw/ArrayRef Int Bool Str/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

has 'id' => (isa => Int, is => 'ro', required => 1);
has 'name' => (isa => NonEmptySimpleStr, is => 'rw', required => 1);
has 'description' => (isa => Str, is => 'rw',);
has 'bool_field' => (isa => Bool, is => 'rw', required => 0);
has 'foo_list' => (
  isa => ArrayRef,
  is => 'rw',
  required => 1,
  writer => 'set_foo_list',
  reader => 'get_foo_list',
);

around get_foo_list => sub { [ $_[1]->foo_list->all ] };

use namespace::clean -except => [ 'meta' ];

__PACKAGE__->table('baz');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', size => 16, is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 255 },
  description => { data_type => 'text', is_nullable => 1 },
  bool_field => {
      data_type => 'char',
      size => '1',
      is_nullable => '1'
  }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many('links_to_foo_list' => 'RTest::TestDB::FooBaz', 'baz');
__PACKAGE__->many_to_many('foo_list' => 'links_to_foo_list' => 'foo');

sub display_name { shift->name; }

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
