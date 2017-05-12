package Tak::ConnectionReceiver;

use Tak::Request;
use Scalar::Util qw(weaken);
use Log::Contextual qw(:log);
use Moo;

with 'Tak::Role::Service';

has requests => (is => 'ro', default => sub { {} });

has channel => (is => 'ro', required => 1);

has service => (is => 'ro', required => 1);

has on_close => (is => 'ro', required => 1);

sub BUILD {
  weaken(my $self = shift);
  my $channel = $self->channel;
  Tak->loop->watch_io(
    handle => $channel->read_fh,
    on_read_ready => sub {
      $channel->read_messages(sub { $self->receive(@_) });
    }
  );
}

sub DEMOLISH {
  Tak->loop->unwatch_io(
    handle => $_[0]->channel->read_fh,
    on_read_ready => 1,
  );
}

sub receive_request {
  my ($self, $tag, $meta, @payload) = @_;
  my $channel = $self->channel;
  unless (ref($meta) eq 'HASH') {
    $channel->write_message(mistake => $tag => 'meta value not a hashref');
    return;
  }
  my $req = Tak::Request->new(
    ($meta->{progress}
        ? (on_progress => sub { $channel->write_message(progress => $tag => @_) })
        : ()),
    on_result => sub { $channel->write_message(result => $tag => $_[0]->flatten) }
  );
  $self->service->start_request($req => @payload);
}

sub receive_progress {
  my ($self, $tag, @payload) = @_;
  $self->requests->{$tag}->progress(@payload);
}

sub receive_result {
  my ($self, $tag, @payload) = @_;
  (delete $self->requests->{$tag})->result(@payload);
}

sub receive_message {
  my ($self, @payload) = @_;
  $self->service->receive(@payload);
}

sub receive_close {
  my ($self, @payload) = @_;
  $self->on_close->(@payload);
}

1;
