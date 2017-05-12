package ComponentUI::TestModel::Foo::Action::SearchSpec::Update;
use Reaction::Class;
use namespace::autoclean;

use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

extends 'Reaction::InterfaceModel::Action';
with 'Reaction::InterfaceModel::Search::UpdateSpec';

has 'first_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 0);
has 'last_name' => (isa => NonEmptySimpleStr, is => 'rw', required => 0);

sub _reflection_info {{ normal => [qw/first_name last_name/] }}

1;
