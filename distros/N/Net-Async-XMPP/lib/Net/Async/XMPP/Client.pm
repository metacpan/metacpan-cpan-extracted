package Net::Async::XMPP::Client;
$Net::Async::XMPP::Client::VERSION = '0.003';
use strict;
use warnings;
use parent qw(Net::Async::XMPP::Protocol);

=head1 NAME

Net::Async::XMPP::Client - asynchronous XMPP client based on L<Protocol::XMPP> and L<IO::Async::Protocol::Stream>.

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

Provides XMPP client support under L<IO::Async>.

This is a subclass of L<Net::Async::XMPP::Protocol>, so some of the documentation is there.

See L<Protocol::XMPP> for more details on this implementation.

=head1 METHODS

=head2 login

 $client->login(
   host => 'talk.google.com',
   jid  => 'foo@gmail.com',
   password => 'blah',
   on_connected => sub { warn "connected!" },
 )

Initiate a login with the given username and password.

All available arguments are listed above.  If the client is already connected
C<host> and C<on_connected> are ignored.  C<on_connected> gets passed the
underlying protocol object.

=cut

sub login {
	my $self = shift;
	my %args = @_;

	die "Already logged in" if $self->is_loggedin;

	# Establish the JabberID if we have one, since that'll affect the hostname used to connect with
	$self->xmpp->jid(delete $args{jid}) if exists $args{jid};

	# If we're not connected yet, then defer the login until we've established a valid connection with the target
	unless($self->is_connected) {
		my $f;
		# If we had a host parameter, assume the user knows what they're up to:
		# just connect directly to that on the given port (or 5222 if none provided)
		if(exists $args{host}) {
			$f = Future->wrap([
				delete($args{host}),
				delete($args{port}) || 5222
			])
		} else {
			$f = $self->srv_lookup(
				$self->xmpp->hostname, 'xmpp-client'
			)
		}
		my $on_connected = delete $args{on_connected};
		return $f->then(sub {
			my $addr = shift;
			($args{host}, $args{service}) = @$addr;
			$self->connect(
				%args,
				on_connected	=> $self->_capture_weakself(sub {
					my $self = shift;
					$on_connected->() if $on_connected;
					$self->login(
						%args,
					);
				}),
			);
		});
	}

	# We have a valid connection, so prepare the login handler.
	my $password = delete $args{password};
	$self->xmpp->{on_login} = sub {
		if(0) {
		# Retrieve whatever we can find from the various features enabled
		$self->xmpp->write_xml([
			'iq',
			'type' => 'get',
			id => $self->xmpp->next_id,
			_content => [[
				'query',
				'xmlns' => 'http://jabber.org/protocol/disco#items'
			]]
		]);
		$self->xmpp->write_xml([
			'iq',
			'type' => 'get',
			id => $self->xmpp->next_id,
			_content => [[
				'query',
				'xmlns' => 'http://jabber.org/protocol/disco#info'
			]]
		]);

		# Request the server's copy of the roster - this should generate some presence events
		$self->xmpp->write_xml([
			'iq',
			'type' => 'get',
			id => $self->xmpp->next_id,
			_content => [[
				'query',
				'xmlns' => 'jabber:iq:roster'
			]]
		]);
		}

# Register our presence so that the server marks us as online and tells people about us
		$self->xmpp->write_xml([
			'presence',
			_content => [
				[
					'priority',
					_content => '1'
				],
				['show']
			]
		]);
	};

	$self->xmpp->{on_login_ready} = sub {
		return $self->xmpp->login(
			password => $password
		) unless $self->xmpp->is_loggedin;
	};
}

sub logout {
	my $self = shift;
	if($self->xmpp->login_complete->is_done) {
		return $self->xmpp->close->on_done($self->curry::close);
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
