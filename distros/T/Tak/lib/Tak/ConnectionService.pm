package Tak::ConnectionService;

use Tak::ConnectionReceiver;
use Tak::JSONChannel;
use Moo;

has receiver => (is => 'ro', writer => '_set_receiver');

has channel => (is => 'ro', writer => '_set_channel');

sub BUILD {
  my ($self, $args) = @_;
  my $channel = $self->_set_channel(
    Tak::JSONChannel->new(map +($_ => $args->{$_}), qw(read_fh write_fh))
  );
  my $receiver = $self->_set_receiver(
    Tak::ConnectionReceiver->new(
      channel => $channel, service => $args->{listening_service},
      on_close => $args->{on_close},
    )
  );
}

sub start_request {
  my ($self, $req, @payload) = @_;
  $self->receiver->requests->{my $tag = "$req"} = $req;
  my $meta = { progress => !!$req->on_progress };
  $self->channel->write_message(request => $tag => $meta => @payload);
}

sub receive {
  my ($self, @payload) = @_;
  $self->channel->write_message(message => @payload);
}

1;
