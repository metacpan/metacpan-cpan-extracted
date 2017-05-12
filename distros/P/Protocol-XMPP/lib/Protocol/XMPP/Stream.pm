package Protocol::XMPP::Stream;
$Protocol::XMPP::Stream::VERSION = '0.006';
use strict;
use warnings;
use parent qw{Protocol::XMPP::Base};

=head1 NAME

Protocol::XMPP::Stream - handle XMPP protocol stream

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use XML::SAX;
use XML::LibXML::SAX::ChunkParser;
use Protocol::XMPP::Handler;
use Protocol::XMPP::Message;
use Authen::SASL;
use MIME::Base64;

=head2 new

Instantiate a stream object. Used for interacting with the underlying XMPP stream.

Takes the following parameters as callbacks:

=over 4

=item * on_queued_write - this will be called whenever there is data queued to be written to the socket

=item * on_starttls - this will be called when we want to switch to TLS mode

=back

and the following scalar parameters:

=over 4

=item * user - username (not the full JID, just the first part)

=item * pass - password

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $self = $class->SUPER::new(%args);
	$self->reset;
	$self->{write_buffer} = [];
	$self;
}

=head2 on_data

Data has been received, pass it over to the SAX parser to trigger any required events.

=cut

sub on_data {
	my $self = shift;
	my $data = shift;
	return $self unless length $data;

	$self->debug("<<< $data");
	$self->{sax}->parse_chunk($data);
	return $self;
}

=head2 queue_write

Queue up a write for this stream. Adds to the existing send buffer array if there is one.

When a write is queued, this will send a notification to the on_queued_write callback if one
was defined.

=cut

sub queue_write {
	my $self = shift;
	my $v = shift;
	$self->debug("Queued a write for [$v]");
	my $f = $self->new_future;
	push @{$self->{write_buffer}}, [ $v, $f ];
	$self->{on_queued_write}->() if $self->{on_queued_write};
	return $f;
}

=head2 write_buffer

Returns the contents of the current write buffer without changing it.

=cut

sub write_buffer { shift->{write_buffer} }

=head2 extract_write

Retrieves next pending message from the write buffer and removes it from the list.

=cut

sub extract_write {
	my $self = shift;
	return unless @{$self->{write_buffer}};
	my $next = shift @{$self->{write_buffer}};
	my ($v) = @$next;
	$self->debug("Extract write [$v]");
	return $v;
}

sub extract_write_and_future {
	my $self = shift;
	return unless @{$self->{write_buffer}};
	my $next = shift @{$self->{write_buffer}};
	$self->debug("Extract write [$next->[0]]");
	return $next;
}

=head2 ready_to_send

Returns true if there's data ready to be written.

=cut

sub ready_to_send {
	my $self = shift;
	$self->debug('Check whether ready to send, current length '. @{$self->{write_buffer}});
	return @{$self->{write_buffer}};
}

sub features_complete {
	my $self = shift;
	$self->{features_complete} ||= $self->new_future;
}

=head2 reset

Reset this stream.

Clears out the existing SAX parsing information and sets up a new L<Protocol::XMPP::Handler> ready to accept
events. Used when we expect a new C<<stream>> element, for example after authentication or TLS upgrade.

=cut

sub reset {
	my $self = shift;
	$self->debug('Reset stream');
	delete $self->{remote_opened};
	delete $self->{features_complete};
	my $handler = Protocol::XMPP::Handler->new(
		stream => $self		# this will be converted to a weak ref to self...
	);
	$self->{handler} = $handler;	# ... but we keep a strong ref to the handler since we control it

	# We need to be able to handle document fragments, so we specify a SAX parser here.
	# TODO If ChunkParser advertised fragment handling as a feature we could require that
	# rather than hardcoding the parser type here.
	{
		local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
		$self->{sax} = XML::SAX::ParserFactory->parser(Handler => $self->{handler}) or die "No SAX parser could be found";
	};
	$self->{data} = '';
	return $self;
}

=head2 dispatch_event

Call the appropriate event handler.

Currently defined events:

=over 4

=item * features - we have received the features list from the server

=item * login - login was completed successfully

=item * message - a message was received

=item * presence - a presence notification was received

=item * subscription - a presence notification was received

=item * transfer_request - a file transfer request has been received

=item * file - a file was received

=back

=cut

sub dispatch_event {
	my $self = shift;
	my $type = shift;
	my $method = 'on_' . $type;
	my $sub = $self->{$method} || $self->can($method);
	return $sub->($self, @_) if $sub;
	$self->debug("No method found for $method");
}

=head2 preamble

Returns the XML header and opening stream preamble.

=cut

sub preamble {
	my $self = shift;
	# TODO yeah fix this
	return [
		qq{<?xml version='1.0' ?>},
		q{<stream:stream to='} . $self->hostname . q{' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>}
	];
}

=head2 jid

Returns the full JID for our user.

If given a parameter, will set the JID to that value, extracting hostname and user by splitting the domain.

=cut

sub jid {
	my $self = shift;
	if(@_) {
		$self->{jid} = shift;
		($self->{user}, $self->{hostname}) = split /\@/, $self->{jid}, 2;
		($self->{hostname}, $self->{resource}) = split qr{/}, $self->{hostname}, 2 if index($self->{hostname}, '/') >= 0;
		return $self;
	}
	return $self->{jid};
}

=head2 user

Username for SASL authentication.

=cut

sub user { shift->{user} }

=head2 pass

Password for SASL authentication.

=cut

sub pass { shift->{pass} }

=head2 hostname

Name of the host

=cut

sub hostname { shift->{hostname} }

=head2 resource 

Fragment used to differentiate this client from any other active clients for this user (as defined by bare JID).

=cut

sub resource { shift->{resource} }

=head2 write_xml

Write a chunk of XML to the stream, converting from the internal representation to XML
text stanzas.

=cut

sub write_xml {
	my $self = shift;
	$self->queue_write($self->_ref_to_xml(@_));
}

=head2 write_text

Write raw text to the output stream.

=cut

sub write_text {
	my $self = shift;
	$self->queue_write($_) for @_;
}

=head2 login

Process the login.

Takes optional named parameters:

=over 4

=item * user - username (not the full JID, just the user part)

=item * password - password or passphrase to use in SASL authentication

=back

=cut

sub login {
	my $self = shift;
	my %args = @_;

	my $user = delete $args{user} // $self->user;
	my $pass = delete $args{password} // $self->pass;

	my $sasl = Authen::SASL->new(
		mechanism => $self->{features}->_sasl_mechanism_list,
		callback => {
			pass => sub { $pass },
			user => sub { $user },
		}
	);

	my $s = $sasl->client_new(
		'xmpp',
		$self->hostname,
		0
	);
	$self->{features}->{sasl_client} = $s;
	my $msg = $s->client_start;
	my $mech = $s->mechanism;
	if(defined($msg) && length($msg)) {
		$self->debug("Have initial message");
		$msg = MIME::Base64::encode($msg, ''); # no linebreaks
	}

	my $f = $self->new_future;
	$self->subscribe_to_event(
		login_success => sub {
			my ($ev) = @_;
			# We only wanted a one-shot notification here
			$ev->unsubscribe;
			$f->done
		}
	);
	$self->debug("SASL mechanism: " . $mech);
	$self->queue_write(
		$self->_ref_to_xml(
			[
				'auth',
				'_ns' => 'xmpp-sasl',
				mechanism => $mech,
				   $msg
				? (_content => $msg)
				: ()
			]
		)
	);
	return $f;
}

sub pending_iq {
	my ($self, $id, $f) = @_;
	die "IQ request $id already exists" if exists $self->{pending_iq}{$id};
	$self->{pending_iq}{$id} = $f;
	$self
}

sub iq_complete {
	my ($self, $id, $iq) = @_;
	die "IQ request $id not found" unless exists $self->{pending_iq}{$id};
	$self->{pending_iq}{$id}->done($iq);
	$self
}

=head2 is_authorised

Returns true if we are authorised already.

=cut

sub is_authorised {
	my $self = shift;
	if(@_) {
		my $state = shift;
		$self->{authorised} = $state;
		$self->dispatch_event($state ? 'authorised' : 'unauthorised');
		if($state) {
			my $f;
			$f = Future->needs_all(
				$self->remote_opened,
				$self->features_complete,
			)->on_done(sub {
				$self->login_complete->done;
				$self->invoke_event(login_success => );
			})->on_ready(sub { undef $f });
		} else {
			$self->login_complete->fail;
			$self->invoke_event(login_fail => );
		}
		return $self;
	}
	return $self->{authorised};
}

sub login_complete {
	my $self = shift;
	$self->{login_complete} ||= $self->new_future
}

=head2 is_loggedin

Returns true if we are logged in already.

=cut

sub is_loggedin {
	my $self = shift;
	if(@_) {
		my $state = shift;
		$self->{loggedin} = $state;
		$self->dispatch_event($state ? 'login' : 'logout');
		return $self;
	}
	return $self->{loggedin};
}

=head2 stream

Override the ->stream method from the base class so that we pick up our own methods directly.

=cut

sub stream { shift }

=head2 next_id

Returns the next ID in the sequence for outgoing requests.

=cut

sub next_id {
	my $self = shift;
	unless($self->{request_id}) {
		$self->{request_id} = 'pxa0001';
	}
	return $self->{request_id}++;
}

=head2 on_tls_complete

Continues the next part of the connection when TLS is complete.

=cut

sub on_tls_complete {
	my $self = shift;
	delete $self->{tls_pending};
	$self->reset;
	$self->write_text($_) for @{$self->preamble};
}

=head2 compose

Compose a new outgoing message.

=cut

sub compose {
	my $self = shift;
	my %args = @_;
	return Protocol::XMPP::Message->new(	
		stream	=> $self,
		%args
	);
}

=head2 subscribe

Subscribe to a new contact. Takes a single JID as target.

=cut

sub subscribe {
	my $self = shift;
	my $to = shift;
	Protocol::XMPP::Contact->new(	
		stream	=> $self,
		jid	=> $to,
	)->subscribe;
}

=head2 unsubscribe

Unsubscribe from the given contact. Takes a single JID as target.
=cut

sub unsubscribe {
	my $self = shift;
	my $to = shift;
	Protocol::XMPP::Contact->new(	
		stream	=> $self,
		jid	=> $to,
	)->unsubscribe;
}

=head2 authorise

Grant authorisation to the given contact. Takes a single JID as target.

=cut

sub authorise {
	my $self = shift;
	my $to = shift;
	Protocol::XMPP::Contact->new(	
		stream	=> $self,
		jid	=> $to,
	)->authorise;
}

=head2 deauthorise

Revokes auth for the given contact. Takes a single JID as target.

=cut

sub deauthorise {
	my $self = shift;
	my $to = shift;
	Protocol::XMPP::Contact->new(	
		stream	=> $self,
		jid	=> $to,
	)->deauthorise;
}

sub remote_opened {
	my $self = shift;
	$self->{remote_opened} ||= $self->new_future
}

sub remote_closed {
	my $self = shift;
	$self->{remote_closed} ||= $self->new_future
}

sub close {
	my $self = shift;
	$self->remote_opened->then(sub {
		$self->queue_write(
			'</stream:stream>'
		)
	})->then(sub {
		$self->remote_closed
	});
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
