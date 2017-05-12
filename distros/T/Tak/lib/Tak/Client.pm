package Tak::Client;

use Tak;
use Tak::Request;
use Moo;

has service => (is => 'ro', required => 1);

has curried => (is => 'ro', default => sub { [] });

sub curry {
  my ($self, @curry) = @_;
  (ref $self)->new(%$self, curried => [ @{$self->curried}, @curry ]);
}

sub send { shift->receive(@_) }

sub receive {
  my ($self, @message) = @_;
  $self->service->receive(@{$self->curried}, @message);
}

sub start {
  my ($self, $register, @payload) = @_;
  my $req = $self->_new_request($register);
  $self->start_request($req, @payload);
  return $req;
}

sub start_request {
  my ($self, $req, @payload) = @_;
  $self->service->start_request($req, @{$self->curried}, @payload);
}

sub request_class { 'Tak::Request' }

sub _new_request {
  my ($self, $args) = @_;
  $self->request_class->new($args);
}

sub do {
  shift->result_of(@_)->get;
}

sub result_of {
  my ($self, @payload) = @_;
  my $done;
  my $result;
  my $req = $self->start({
    on_result => sub { $result = shift },
  }, @payload);
  Tak->loop_until($result);
  return $result;
}

sub clone_or_self {
  my ($self) = @_;
  (ref $self)->new(
    service => $self->service->clone_or_self, 
    curried => [ @{$self->curried} ],
  );
}

1;
