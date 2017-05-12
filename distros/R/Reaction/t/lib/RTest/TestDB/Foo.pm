package # hide from PAUSE
  RTest::TestDB::Foo;

use Moose;
extends 'DBIx::Class';

use MooseX::Types::Moose qw/ArrayRef Int/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

has 'id' => (isa => Int, is => 'ro', required => 1);
has 'first_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 1);
has 'last_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 1);
has 'bars' => (isa => ArrayRef, is => 'ro');
has 'bazes' => (
  isa => ArrayRef,
  required => 1,
  reader => 'get_bazes',
  writer => 'set_bazes'
);

use namespace::clean -except => [ 'meta' ];

__PACKAGE__->load_components(qw/IntrospectableM2M Core/);
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', size => 16, is_auto_increment => 1 },
  first_name => { data_type => 'varchar', size => 255 },
  last_name => { data_type => 'varchar', size => 255 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
                      'bars' => 'RTest::TestDB::Bar',
                      { 'foreign.foo_id' => 'self.id' }
                     );

__PACKAGE__->has_many('foo_baz' => 'RTest::TestDB::FooBaz', 'foo');
__PACKAGE__->many_to_many('bazes' => 'foo_baz' => 'baz');

sub display_name {
  my $self = shift;
  return join(' ', $self->first_name, $self->last_name);
}

around get_bazes => sub { [ $_[1]->bazes_rs->all ] };

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
