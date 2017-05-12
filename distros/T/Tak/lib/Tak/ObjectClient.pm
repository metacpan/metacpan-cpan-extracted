package Tak::ObjectClient;

use Tak::ObjectProxy;
use Moo;

with 'Tak::Role::ObjectMangling';

has remote => (is => 'ro', required => 1);

has object_service => (is => 'lazy');

sub _build_object_service {
  my ($self) = @_;
  my $remote = $self->remote;
  $remote->ensure(object_service => 'Tak::ObjectService');
  $remote->curry('object_service');
}

sub proxy_method_call {
  my ($self, @call) = @_;
  my $client = $self->object_service;
  my $ready = $self->encode_objects(\@call);
  my $context = wantarray;
  my $res = $client->do(call_method => $context => $ready);
  my $unpacked = $self->decode_objects($res);
  if ($context) {
    return @$unpacked;
  } elsif (defined $context) {
    return $unpacked->[0];
  } else {
    return;
  }
}

sub proxy_death {
  my ($self, $proxy) = @_;
  $self->client->do(remove_object => $proxy->{tag});
}

sub inflate {
  my ($self, $tag) = @_;
  bless({ client => $self, tag => $tag }, 'Tak::ObjectProxy');
}

sub deflate {
  my ($self, $obj) = @_;
  unless (ref($obj) eq 'Tak::ObjectProxy') {
    die "Can't deflate non-proxied object ${obj}";
  }
  return +{ __proxied_object__ => $obj->{tag} };
}

sub new_object {
  my ($self, $class, @args) = @_;
  $self->proxy_method_call($class, 'new', @args);
}

1;
