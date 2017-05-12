package ComponentUI::Controller::TestModel::Foo;

use Moose;
BEGIN { extends 'Reaction::UI::Controller::Collection::CRUD'; }

use aliased 'Reaction::UI::ViewPort::SearchableListViewContainer';
use aliased 'ComponentUI::TestModel::Foo::SearchSpec';
use aliased 'ComponentUI::TestModel::Foo::Action::SearchSpec::Update';

__PACKAGE__->config(
  model_name => 'TestModel',
  collection_name => 'Foo',
  action => {
    base => { Chained => '/base', PathPart => 'testmodel/foo' },
    list => {
      ViewPort => {
        action_prototypes => { delete_all => 'Delete all records' },
        excluded_fields => [qw/id/],
        action_order => [qw/delete_all create/],
        enable_order_by => [qw/last_name/],
        Member => {
          action_order => [qw/view update delete/],
        },
      },
    },
    view => {
      ViewPort => {
        excluded_fields => [qw/id/],
      },
    },
    delete => {
      ViewPort => {message => 'Are you sure you want to delete this Foo?'}
    },
  },
);

for my $action (qw/view create update/){
  __PACKAGE__->config(
    action => {
      $action => {
        ViewPort => {
          container_layouts => [
            { name => 'primary', fields => [qw/first_name last_name/]},
            {
              name => 'secondary',
              label => 'Optional Label',
              fields => [qw/bars bazes/],
            },
          ],
        },
      },
    }
  );
}

override _build_action_viewport_map => sub {
  my $map = super();
  $map->{list} = SearchableListViewContainer;
  return $map;
};

override _build_action_viewport_args => sub {
  my $args = super();
  $args->{list}{spec_class} = SearchSpec;
  $args->{list}{action_class} = Update;
  return $args;
};

sub object : Chained('base') PathPart('id') CaptureArgs(1) {
  my ($self, $c, $object) = @_;
  $self->next::method($c, $object);
  # just as failing use case
}

1;

__END__;
