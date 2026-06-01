package Protocol::Tus::Upload;
{ our $VERSION = '0.004' }
use Moo;
use v5.24;
use warnings;
use experimental qw< signatures >;
use namespace::clean;

has id    => (is => 'ro', required => 1);
has model => (is => 'ro', required => 1);

sub cleanup ($self) {
   $self->model->cleanup($self->id);
   return $self;
}

sub finalize ($self) {
   $self->model->finalize($self->id);
   return $self;
}

sub get_info ($self) {
   return $self->model->get_info($self->id);
}

sub get_offset ($self) {
   return $self->model->get_offset($self->id);
}

sub is_complete ($self) {
   return $self->model->is_complete($self->id);
}

sub save_chunk ($self, $offset, $dref) {
   $self->model->save_chunk($self->id, $offset, $dref);
   return $self;
}

sub set_length ($self, $length) {
   $self->model->set_length($self->id, $length);
   return $self;
}

1;
