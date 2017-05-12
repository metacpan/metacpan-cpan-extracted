package ORTestBridge;
use Moo;

use Object::Remote;

has object => (is => 'lazy');

sub _build_object { ORTestClass->new::on('-') }

sub call {
  my ($self, $method, @args) = @_;
  return $self->object->$method(@args);
}

1;
