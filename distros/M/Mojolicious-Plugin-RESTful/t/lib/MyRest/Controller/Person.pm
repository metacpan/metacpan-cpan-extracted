package MyRest::Controller::Person;
use Mojo::Base 'Mojolicious::Controller';

my %people = (
  eric => {
    id => 'eric',
    name => 'Eric Lee',
    age => 18,
  },
  rose => {
    id => 'rose',
    name => 'Rose Well',
    age => 20
  }
);
sub people_list {
  my $self = shift;
  $self->render(json => [map { $people{$_} }sort keys %people]);
}

sub people_create {
  my $self = shift;
  my %person = map {
    $_ => $self->param($_);
  } qw(id name age);
  $people{$person{id}} = \%person;
  $self->render(json => \%person);
}

sub people_options {
  my $self = shift;
  $self->res->headers->append(Allow => 'GET POST');
  $self->render(text => '');
}

sub person_retrieve {
  my $self = shift;
  my $id = $self->param("person");
  $self->app->log->debug($self->dumper($id));
  return $self->rendered(404) unless $people{$id};
  $self->render(json => $people{$id});
}

sub person_update {
  my $self = shift;
  my %person = map {
    $_ => $self->param($_);
  } qw(id name age);
  $people{$person{id}} = \%person;
  $self->render(json => \%person);
}

sub person_delete {
  my $self = shift;
  my $id = $self->param('person');
  delete $people{$id};
  $self->render(json => { message => 'ok'});
}

sub person_patch {
  my $self = shift;
  my $form = $self->req->params->to_hash;
  my $id = $self->param("person");
  return $self->rendered(404) unless $people{$id};
  map { $people{$id}->{$_} = $form->{$_} } keys %$form;
  $self->app->log->debug($self->dumper($form));
  $self->render(json => $people{$id});
}

sub person_options {
  my $self = shift;
  $self->res->headers->append(Allow => 'GET POST PUT PATCH DELETE');
  $self->render(text => '');
}

1;

