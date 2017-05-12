package Mojo::Redis::Subscription;

=head1 NAME

Mojo::Redis::Subscription - DEPRECATED Redis pub/sub client

=head1 SYNOPSIS

See L<Mojo::Redis>.

=cut

use Mojo::Base 'Mojo::Redis'; # This may change in the future!

has type => 'subscribe';

sub connect {
  my $self = shift;
  my $channels = $self->channels;
  my $command = $self->type;

  $self->SUPER::connect(@_);

  push @{ $self->{cb_queue} }, (sub { shift->emit(data => @_) }) x (@$channels - 1);

  $self->execute(
    [ $command => @$channels ],
    sub {
      my $self = shift;
      Scalar::Util::weaken($self);
      $self->emit(data => @_);
      $self->protocol->on_message(sub {
        my ($parser, $message) = @_;
        my $data = $self->_reencode_message($message) or return;
        $self->emit(data => $data);
        $self->emit(message => @$data[2, 1]) if $data->[0] eq 'message';
        $self->emit(message => @$data[3, 2, 1]) if $data->[0] eq 'pmessage';
      });
    }
  );
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
