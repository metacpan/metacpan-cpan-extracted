package MojoX::NetstringStream;

use Mojo::Base 'Mojo::EventEmitter';

use Carp;

our $VERSION  = '0.06';

has [qw(buf debug stream want)];

sub new {
	my ($class, %args) = @_;
	my $stream = $args{stream};
	croak 'no stream?' unless $stream;
	my $self = $class->SUPER::new();
	my $buf = '';
	my $want = 0;
	$self->{buf} = \$buf; # buffer for incomple chunks
	$self->{want} = \$want; # if set: number of bytes expected
	$self->{stream} = $stream;
	$self->{debug} = $args{debug} // 0;
	$self->{maxsize} = $args{maxsize};
	$stream->timeout(0);
	$stream->on(read => sub{ $self->_on_read(@_); });
	$stream->on(close => sub{ $self->_on_close(@_); });
	return $self;
}

sub _on_read {
	my ($self, $stream, $bytes) = @_;
	my $buf = $self->{buf};
	my $want = $self->{want};
	my $maxsize = $self->{maxsize};

	$$buf .= $bytes;
	say "on_read: bytes: $bytes buf now: $$buf" if $self->{debug};
	
	while (1) { # fixme: does this always end? 
		if (!$$want) {
			return unless $$buf;
			#return if $$buf !~ /^(\d*):/;
			return unless (my $i = index($$buf, ':')) > 0;
		 	# fixme: we don't detect a framing error this way
		 	# but just hang when that happens
			#$$want = $1;
			$$want = substr($$buf, 0, $i);
			if ($maxsize and $$want > $maxsize) {
				$self->emit(nserr => "netstring too big: $$want > $maxsize");
				return;
			}
			#substr($$buf, 0, length($1)+1, ''); # 123:
			substr($$buf, 0, $i+1, '');
			$$want++; # include trailing ,
			#say "on_read: want: $$want buf now: $$buf";
		}

		return if $$want > length($$buf);

		my $chunk = substr($$buf, 0, $$want, '');
		if (chop $chunk ne ',') {
			$self->emit(nserr => 'no trailing , in chunk');
			return;
		}
		$$want = 0;
		#say "on_read: chunk: $chunk buf now: $$buf";

		$self->emit(chunk => $chunk);
	}
}

sub _on_close {
	my ($self, $stream) = @_;
	$self->emit(close => $stream);
	say 'got close!' if $self->{debug};
	delete $self->{stream};
}

sub close {
	my ($self) = @_;
	$self->stream->close;
	%$self = ();
}

sub write {
	use bytes;
	my ($self, $chunk) = @_;
	my $len = length($chunk);
	my $out = sprintf('%u:%s,', $len, $chunk);
	say "write: $out" if $self->{debug};
	$self->{stream}->write($out);
}

#sub DESTROY {
#	my $self = shift;
#	say 'destroying ', $self;
#}

1;


=encoding utf8

=head1 NAME

MojoX::NetstringStream - Turn a (tcp) stream into a NetstringStream

=head1 SYNOPSIS

  use MojoX::NetstringStream;

  my $clientid = Mojo::IOLoop->client({
    port => $port,
  } => sub {
    my ($loop, $err, $stream) = @_;
    my $ns = MojoX::NetstringStream->new(stream => $stream);
      $ns->on(chunk => sub {
         my ($ns, $chunk) = @_;
         say 'got chunk: ', $chunk;
         ...
      });
      $ns->on(close => sub {
         say 'got close';
         ...
      });
  });

=head1 DESCRIPTION

L<MojoX::NetstringStream> is a wrapper around L<Mojo::IOLoop::Stream> that
adds framing using the netstring encoding.

=head1 ATTRIBUTES

=head2 stream

The underlying Mojo::IOLoop stream to use for reading and writing

=head2 debug

Enables debugging

=head2 maxsize

Maximum size of the accepted netstring frames, if set.  A nserr event is
raised when a oversized frame is received.

Default: none

=head1 EVENTS

L<MojoX::NetstringStream> inherits all events from L<Mojo::EventEmitter> and can
emit the following new ones.

=head2 chunk

  $ns->on(chunk => sub {
    my ($ns, $chunk) = @_;
    ...
  });

Emitted for every (full) netstring received on the underlying stream.

=head2 close

  $ns->on(close => sub {
    my $ns = shift;
    ...
  });

Emitted if the underlying stream gets closed.

=head2 nserr

  $ns->on(nserr => sub {
    my ($ns, $err) = @_;
    ...
  });

Emitted if there was some kind of framing error, currenty either a missing
',' at the end or a oversized frame.

=head1 ATTRIBUTES

L<MojoX::NetstringStream> implements the following attributes.

=head2 stream

  my $stream = $ns->stream;

The underlying L<Mojo::IOLoop::Stream>-like stream

=head2 debug

  $ls->debug = 1;

Enables or disables debugging output.

=head1 METHODS

L<MojoX::NetstringStream> inherits all methods from
L<Mojo::EventEmitter> and implements the following new ones.

=head2 new

  my $ns = MojoX::NetstringStream->new(
      stream => $stream,
      debug => $debug,
  );

Construct a new L<MojoX::NetstringStream> object.  The stream argument must
behave like a L<Mojo::IOLoop::Stream> object.  The debug argument is
optional and just sets the debug attribute.

=head2 write

  $ns->write($chunk);

Writes chunk to the underlying stream as a netstring.

=head1 SEE ALSO

=over

=item *

L<Mojo::IOLoop>, L<Mojo::IOLoop::Stream>, L<http://mojolicious.org>: the L<Mojolicious> Web framework

=item *

L<https://cr.yp.to/proto/netstrings.txt>: netstrings specification.

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

This software is copyright (c) 2017 by Wieger Opmeer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

