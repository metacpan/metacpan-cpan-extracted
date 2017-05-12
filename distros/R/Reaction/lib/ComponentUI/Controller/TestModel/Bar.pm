package ComponentUI::Controller::TestModel::Bar;

use Moose;
BEGIN { extends 'Reaction::UI::Controller::Collection::CRUD'; }

__PACKAGE__->config(
  model_name => 'TestModel',
  collection_name => 'Bar',
  action => {
    base => { Chained => '/base', PathPart => 'testmodel/bar' },
    create => { ViewPort => { layout => 'bar/create' } },
    list => {
      ViewPort => {
        enable_order_by => [qw/name foo published_at/],
        coerce_order_by => { foo => ['foo.last_name', 'foo.first_name'] },
        layout => 'bar/collection',
        member_class => 'Reaction::UI::ViewPort::Object',
        Member => { layout => 'bar/member' }
      },
    },
  },
);

around get_collection => sub {
  my ($orig, $self, $c) = @_;
  my $collection = $self->$orig($c);
  return $collection->where({}, { prefetch => 'foo' });
};

1;

__END__;

#put this aside for now
sub create :Chained('base') {
  my $self = shift;
  my ($c) = @_;
  my $action_vp = $self->next::method(@_);
  my $self_uri = $c->uri_for($self->action_for('create'));
  $action_vp->action($self_uri);

  my $params = $c->request->parameters;
  if ( defined $params->{return_to_uri} && $params->{return_to_uri} ){
    if( $params->{return_to_uri} ne $c->request->uri ){
      $action_vp->layout_args->{return_to_uri} = $params->{return_to_uri};
    }
  } elsif( $c->request->referer ne $c->request->uri) {
    $action_vp->layout_args->{return_to_uri} = $c->request->referer;
  }

  return $action_vp;
}

sub on_create_close_callback {
  my($self, $c, $vp) = @_;
  if ( my $return_to_uri =  delete $c->request->parameters->{return_to_uri} ){
    $c->response->redirect( $return_to_uri );
  } else {
    $self->redirect_to( $c, 'list' );
  }
  $c->detach;
}

1;
