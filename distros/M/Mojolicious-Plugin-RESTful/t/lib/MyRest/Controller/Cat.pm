package MyRest::Controller::Cat;
use Mojo::Base 'Mojolicious::Controller';

my %cats = ();

has 'owner' => sub {
  shift->param("person");
};

sub person_cats_list {
  my $self = shift;
  my %my_cats = %{$cats{$self->owner}};
  $self->render(json => [map { $my_cats{$_} } sort keys %my_cats]);
}

sub person_cats_create {
  my $self = shift;
  my %cat = (owner => $self->owner);
  map {
    $cat{$_} = $self->param($_);
  } qw(id color);
  $cats{$cat{owner}}->{$cat{id}} = \%cat;
  $self->app->log->debug($self->dumper(\%cats));
  $self->render(json => \%cat);
}

sub person_cats_options {
  my $self = shift;
  $self->res->headers->append(Allow => 'GET POST');
  $self->render(text => '');
}

sub person_cat_retrieve {
  my $self = shift;
  my %my_cats = %{$cats{$self->owner}};
  my $id = $self->param("cat");
  return $self->rendered(404) unless $my_cats{$id};
  $self->render(json => $my_cats{$id});
}

sub person_cat_update {
  my $self = shift;
  my $cat = $cats{$self->owner}->{$self->param("cat")};
  $cat->{color} = $self->param("color");
  $self->render(json => $cat);
}

sub person_cat_delete {
  my $self = shift;
  my $my_cats = $cats{$self->owner};
  return $self->render(json => { message => 'ok'}) unless $my_cats;

  delete $my_cats->{$self->param('cat')};
  $self->render(json => { message => 'ok'});
}

sub person_cat_patch {
  my $self = shift;
  my $form = $self->req->params->to_hash;
  my $my_cats = $cats{$self->owner};
  my $id = $self->param("cat");
  return $self->rendered(404) unless $my_cats->{$id};
  map { $my_cats->{$id}->{$_} = $form->{$_} } keys %$form;
  $self->app->log->debug($self->dumper($form));
  $self->render(json => $my_cats->{$id});
}

sub person_cat_options {
  my $self = shift;
  $self->res->headers->append(Allow => 'GET POST PUT PATCH DELETE');
  $self->render(text => '');
}

1;

