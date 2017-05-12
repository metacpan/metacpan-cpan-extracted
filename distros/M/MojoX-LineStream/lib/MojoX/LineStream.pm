package MojoX::LineStream;

use Mojo::Base 'Mojo::EventEmitter';

use Carp;

our $VERSION  = '0.01';

has [qw(_buf debug stream)];

sub new {
	my ($class, %args) = @_;
	my $stream = $args{stream};
	croak 'no stream?' unless $stream;
	my $self = $class->SUPER::new();
	my $_buf = '';
	$self->{_buf} = \$_buf;
	$self->{stream} = $stream;
	$self->{debug} = $args{debug} // 0;
	$stream->timeout(0);
	$stream->on(read => sub{ $self->on_read(@_); });
	$stream->on(close => sub{ $self->on_close(@_); });
	return $self;
}

sub on_read {
	my ($self, $stream, $bytes) = @_;
	my $_buf = $self->_buf;
	$$_buf .= $bytes;
	say '_buf now: ', $$_buf if $self->debug;
	return if $$_buf !~ /\n/;
	while ($$_buf =~ s/^([^\n]+)\n//) {
		my $line = $1;
		$self->emit(line => $line);
	}
}

sub on_close {
	my ($self, $stream) = @_;
	$self->emit(close => 1);
	say 'got close!' if $self->debug;
	delete $self->{stream};
}

sub writeln {
	my ($self, $line) = @_;
	say 'writeln ', $line if $self->debug;
	$self->stream->write("$line\n");
}

1;

=encoding utf8

=head1 NAME

MojoX::LineStream - Turn a (tcp) stream into a line based stream

=head1 SYNOPSIS

  use MojoX::LineStream;

  my $clientid = Mojo::IOLoop->client({
    port => $port,
  } => sub {
    my ($loop, $err, $stream) = @_;
    my $ls = MojoX::LineStream->new(stream => $stream);
      $ls->on(line => sub {
         my ($;s, $line) = @_;
         say 'got line: ', $line;
         ...
      });
      $ls->on(close => sub {
         say 'got close';
         ...
      });
  });

=head1 DESCRIPTION

L<MojoX::LineStream> is a wrapper around L<Mojo::IOLoop::Stream> that
adds 'framing' based on lines terminated by a newline character.

=head1 EVENTS

L<MojoX::LineStream> inherits all events from L<Mojo::EventEmitter> and can
emit the following new ones.

=head2 line

  $ls->on(line => sub {
    my ($ls, $line) = @_;
    ...
  });

Emitted for every (full) line received on the underlying stream.  The line
passed on to the callback does not include the terminating newline
character.

=head2 close

  $;s->on(close => sub {
    my $;s = shift;
    ...
  });

Emitted if the underlying stream gets closed.

=head1 ATTRIBUTES

L<MojoX::LineStream> implements the following attributes.

=head2 stream

  my $stream = $ls->stream;

The underlying L<Mojo::IOLoop::Stream>-like stream

=head2 debug

  $ls->debug = 1;

Enables or disables debugging output.

=head1 METHODS

L<MojoX::LineStream> inherits all methods from
L<Mojo::EventEmitter> and implements the following new ones.

=head2 new

  my $ls = MojoX::LineStream->new(
      stream => $stream,
      debug => $debug,
  );

Construct a new L<MojoX::LineStream> object.  The stream argument must
behave like a L<Mojo::IOLoop::Stream> object.  The debug argument is
optional and just sets the debug attribute.

=head2 writeln

  $ls->writeln($line);

Writes line to the underlying stream, adding a newline character at the end.

=head1 SEE ALSO

=over

=item *

L<Mojo::IOLoop>, L<Mojo::IOLoop::Stream>, L<http://mojolicious.org>: the L<Mojolicious> Web framework

=back

=head1 ACKNOWLEDGEMENT

This software has been developed with support from L<STRATO|https://www.strato.com/>.
In German: Diese Software wurde mit Unterstützung von L<STRATO|https://www.strato.de/> entwickelt.

=head1 AUTHORS

=over 4

=item *

Wieger Opmeer <wiegerop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Wieger Opmeer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

