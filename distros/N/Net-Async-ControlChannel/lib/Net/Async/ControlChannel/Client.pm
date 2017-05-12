package Net::Async::ControlChannel::Client;
$Net::Async::ControlChannel::Client::VERSION = '0.005';
use strict;
use warnings;
use parent qw(Mixin::Event::Dispatch);

=encoding utf8

=head1 NAME

Net::Async::ControlChannel::Client - L<IO::Async> support for L<Protocol::ControlChannel>.

=head1 VERSION

Version 0.005

=head1 DESCRIPTION

Provides the client half for a control channel connection.

=cut

use Protocol::ControlChannel;
use Future;
use curry::weak;
use IO::Async::Stream;
use Scalar::Util qw(weaken);

=head1 METHODS

=cut

=head2 new

Instantiate a new client object.

Expects the following named parameters:

=over 4

=item * loop - the L<IO::Async::Loop> we will attach to

=item * host - which host we're connecting to

=item * port - the port to connect to

=back

Returns the instance.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		loop => (delete($args{loop}) or die 'no loop?'),
		%args
	}, $class;
	weaken($self->{loop});
	$self->{protocol} = Protocol::ControlChannel->new;
	$self;
}

=head2 loop

The L<IO::Async::Loop> object. Used internally.

=cut

sub loop { shift->{loop} }

=head2 proto

The L<Protocol::ControlChannel> instance. Used internally.

=cut

sub proto { shift->{protocol} }

=head2 connection

A L<Future> which resolves when the connection is established.

=cut

sub connection { shift->{connection} ||= Future->new }

=head2 start

Connects to the target host, returning a L<Future> which will
resolve once the connection is ready (this L<Future> is also
available via L</connection>).

=cut

sub start {
	my $self = shift;
	my $port = $self->{port};
	my $host = $self->{host};
	$self->loop->connect(
		addr => {
			ip => $host || 'localhost',
			family => 'inet',
			socktype => 'stream',
			port => $port || 0,
		},
	)->then(sub {
		my $sock = shift;
		my $stream = IO::Async::Stream->new(handle => $sock);
		$stream->configure(
			on_read => $self->curry::weak::incoming_message,
		);
		$self->loop->add($stream);
		$self->connection->done($stream);
	})->transform(done => sub { $self });
}

=head2 incoming_message

Called internally when we have data from the server.

=cut

sub incoming_message {
	my $self = shift;
	my (undef, $buffer, $eof) = @_;
	while(my $frame = $self->proto->extract_frame($buffer)) {
		$self->invoke_event(message => $frame->{key}, $frame->{value});
	}
	if($eof) {
		$self->invoke_event(disconnect => );
	}
	return 0;
}

=head2 dispatch

Dispatches the given key, value pair to the remote.

Expects two parameters:

=over 4

=item * $k - a Perl string representing the key we're sending over. Typically
this will be 'some.dotted.string'.

=item * $v - the value to send over, either a reference or a byte string.

=back

Unicode characters are allowed for the key, but if you want to send non-ASCII
text data in the content, it should be encoded explicitly:

 $cc->dispatch("utf₈.is.fine" => Encode::encode('UTF-8' => "ƃuıpoɔuǝ spǝǝu"));

=cut

sub dispatch {
	my $self = shift;
	my ($k, $v) = @_;
	my $holder;
	$holder = $self->connection->then(sub {
		my $stream = shift;
		my $f = Future->new;
		$stream->write(
			$self->proto->create_frame($k => $v),
			on_flush => sub { $f->done }
		);
		weaken $holder;
		$f;
	});
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
