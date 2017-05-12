package Reaction::InterfaceModel::Search::UpdateSpec;

use Reaction::Role;
use Method::Signatures::Simple;
use aliased 'Reaction::InterfaceModel::Search::Spec', 'SearchSpec';
use namespace::clean -except => 'meta';

# FIXME - has '+attr' broken, copied from Reaction::InterfaceModel::Action
#has '+target_model' => (isa => SearchSpec);
has target_model => (
  isa => SearchSpec,
  is => 'ro',
  required => 1,
  metaclass => 'Reaction::Meta::Attribute'
);

requires '_reflection_info';

override BUILDARGS => method () {
  my $args = super;
  my $model = $args->{target_model};
  my $reflected = $self->_reflection_info;
  foreach my $attr (@{$reflected->{empty}||[]}) {
    if ($model->${\"has_${attr}"}) {
      $args->{$attr} = $model->$attr;
    } else {
      $args->{$attr} = '';
    }
  }
  foreach my $attr (@{$reflected->{normal}||[]}) {
    my $has = $model->can("has_${attr}")||sub {1};
    $args->{$attr} = $model->$attr if $model->$has;
  }
  $args;
};

method do_apply () {
  my $data = $self->parameter_hashref;
  my $spec = $self->target_model;
  foreach my $name (keys %$data) {
    # note: this assumes plain is => 'rw' attrs on the backend
    # which is safe since we control it. Also, we assume '' means
    # clear - this may not be safe later but is for now
    if (length(my $value = $data->{$name})) {
      $spec->$name($value);
    } else {
      $spec->${\"clear_${name}"};
    }
  }
  $spec;
}

1;

