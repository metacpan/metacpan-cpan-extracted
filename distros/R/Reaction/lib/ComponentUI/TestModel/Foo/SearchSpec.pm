package ComponentUI::TestModel::Foo::SearchSpec;
use Reaction::Class;
use namespace::autoclean;

use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

with 'Reaction::InterfaceModel::Search::Spec';

has 'first_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 0);
has 'last_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 0);

sub _build__search_spec {
  my($self) = @_;
  my %search;
  $search{first_name} = $self->first_name if $self->has_first_name;
  $search{last_name} = $self->last_name if $self->has_last_name;
  return [\%search];
}

# no special packing/unpacking required for Foo
sub _to_string_pack_value { $_[1] }
sub _from_string_unpack_value { $_[1] }

1;
