package Tak::Request;

use Tak::Result;
use Moo;

has on_progress => (is => 'ro');

has on_result => (is => 'ro', required => 1);

has is_done => (is => 'rw', default => sub { 0 });

sub progress {
  my ($self, @report) = @_;
  if (my $cb = $self->on_progress) {
    $cb->(@report);
  }
}

sub result {
  my ($self, $type, @data) = @_;
  $self->is_done(1);
  $self->on_result->(Tak::Result->new(type => $type, data => \@data));
}

sub flatten {
  my ($self) = @_;
  return ($self->type, @{$self->data});
}

sub success { shift->result(success => @_) }
sub mistake { shift->result(mistake => @_) }
sub failure { shift->result(failure => @_) }
sub fatal { shift->result(fatal => @_) }

1;
