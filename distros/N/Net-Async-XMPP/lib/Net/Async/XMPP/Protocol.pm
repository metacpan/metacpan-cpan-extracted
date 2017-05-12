package Net::Async::XMPP::Protocol;
$Net::Async::XMPP::Protocol::VERSION = '0.003';
use strict;
use warnings;
use parent qw{IO::Async::Stream};

=head1 NAME

Net::Async::XMPP::Protocol - common protocol support for L<Net::Async::XMPP>

=head1 VERSION

Version 0.003

=head1 METHODS

=cut

use IO::Async::Resolver::DNS;
use IO::Async::SSL;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use Socket qw(getnameinfo IPPROTO_TCP NI_NUMERICHOST NI_NUMERICSERV SOCK_STREAM);
use Protocol::XMPP::Stream;
use Future::Utils 'repeat';
use curry::weak;

# 'resolver' for regular lookup, 'dns' for DNS-specific
# regular resolver does not appear to implement weight/priority,
# so if you're using a service such as google.com then you'll need
# 'dns' here.
use constant SRV_IMPLEMENTATION => 'dns';

=head2 xmpp

Accessor for the underyling XMPP L<Protocol::XMPP::Stream> object.

=cut

sub xmpp {
	my $self = shift;
	unless($self->{xmpp}) {
		$self->{xmpp} = Protocol::XMPP::Stream->new(
			debug => $self->{debug} ? 1 : 0,
			future_factory => $self->loop->curry::weak::new_future,
			on_queued_write => $self->_capture_weakself(sub {
				my $self = shift;
				$self->{_writing_future} = (repeat {
					my $next = $self->xmpp->extract_write_and_future;
					$self->write($next->[0])->on_ready($next->[1]);
				} while => sub {
					$self->xmpp->ready_to_send
				})->on_ready(sub {
					$self->maybe_invoke_event('on_write_finished');
					delete $self->{_writing_future}
				});
			}),
			on_starttls => $self->_capture_weakself(sub {
				my $self = shift;
				$self->on_starttls;
			}),
		);
	}
	return $self->{xmpp};
}

=head2 configure

Configure our handlers.

=cut

sub configure {
	my $self = shift;
	my %params = @_;

	$self->{state} ||= {
		connected => 0,
		loggedin => 0
	};
	$self->{debug} = delete $params{debug} if exists $params{debug};

   $self->{on_write_finished} = $self->_replace_weakself(delete $params{on_write_finished})
      if $params{on_write_finished};
	foreach (qw(on_message on_roster on_contact_request on_contact on_login on_presence on_connected)) {
		if(my $handler = delete $params{$_}) {
			$self->xmpp->{$_} = $self->_replace_weakself($handler);
		}
	}

	$self->SUPER::configure(%params);
}

=head2 on_starttls

Upgrade the underlying stream to use TLS.

=cut

sub on_starttls {
	my $self = shift;
	$self->xmpp->debug("Upgrading to TLS");

	require IO::Async::SSLStream;

	$self->loop->SSL_upgrade(
		handle => $self,
		SSL_verify_mode => SSL_VERIFY_NONE,
		on_upgraded => $self->_capture_weakself(sub {
			my ($self, $sock) = @_;
			$self->xmpp->on_tls_complete;
		}),
		on_error => sub { die "error @_"; }
	);
}

sub is_connected { shift->{state}{connected} }
sub is_loggedin { shift->{state}{loggedin} }

=head2 on_read

Proxy incoming data through to the underlying L<Protocol::XMPP::Stream>.

=cut

sub on_read {
	my ($self, $buffref, $closed) = @_;

	$self->xmpp->on_data($$buffref);
	$self->xmpp->remote_closed->done if $closed && !$self->xmpp->remote_closed->is_ready;

# Entire buffer is handled by the Protocol object so no need for partial processing here.
	$$buffref = '';
	return 0;
}

=head2 connect

 $protocol->connect(
   on_connected => sub { warn "connected!" },
   host         => 'talk.google.com',
 )

Establish a connection to the XMPP server.

All available arguments are listed above.  C<on_connected> gets passed the
underlying protocol object.

=cut

sub connect {
	my $self = shift;
	my %args = @_;
	my $on_connected = delete $args{on_connected} || $self->{on_connected};

	$self->SUPER::connect(
		# Default port is 5222, but this can be overridden in %args.
		service		=> 5222,
		socktype	=> SOCK_STREAM,
		host		=> $self->{host},
		%args,
	)->then(sub {
		$self->{state}{connected} = 1;
		$self->xmpp->queue_write($_) for @{$self->xmpp->preamble};
		$on_connected->($self) if $on_connected;
		$self->xmpp->login_complete;
	})->on_fail(sub {
		warn "Connection failure: @_";
	})
}

=head2 srv_lookup

Performs a SRV lookup for the given domain and type.

This should resolve to a list of (host, port) arrayrefs, in decreasing
order of preference.

 $proto->srv_lookup('example.com', 'xmpp-client')->on_done(sub {
  printf "Service available at %s:%d\n", @$_ for @_;
 });

=cut

sub srv_lookup {
	shift->${\("srv_lookup_" . SRV_IMPLEMENTATION)}(@_);
}

sub srv_lookup_resolver {
	my ($self, $domain, $type) = @_;
	my $resolver = $self->loop->resolver;
	$type //= 'xmpp-client';

	$resolver->getaddrinfo(
		host     => $domain,
		service  => $type,
		socktype => 'stream',
	)->transform(
		done => sub {
			my @result;
			foreach my $addr (@_) {
				if($addr->{protocol} == IPPROTO_TCP) {
					my ($err, $host, $port) = getnameinfo $addr->{addr}, NI_NUMERICHOST | NI_NUMERICSERV;
					$self->debug_printf("Had %s:%d from %s lookup on %s, error status %d", $host, $port, $type, $domain, $err);
					push @result, [ $host => $port ];
				} else {
					$self->debug_printf("$type for $domain can be reached at " .
						"socket(%d,%d,%d) + connect('%v02x')",
						@{$addr}{qw( family socktype protocol addr )});
				}
			}
			return @result;
		}
	)
}

sub srv_lookup_dns {
	my ($self, $domain, $type) = @_;
	my $resolver = $self->loop->resolver;
	$type //= 'xmpp-client';

	my $f = $self->loop->new_future;
	$resolver->res_query(
		dname    => "_${type}._tcp.$domain",
		type     => 'SRV',
		on_resolved => sub { $f->done(@_) },
		on_error => sub { $f->fail(@_) },
	);
	$f->transform(
		done => sub {
			my $pkt = shift;
			my @result;
			foreach my $srv (grep $_->type eq 'SRV', $pkt->answer) {
				$self->debug_printf("Had %s:%d from %s lookup on %s", $srv->{target}->name, $srv->{port}, $type, $domain);
				push @result, [
					$srv->{target}->name => $srv->{port}
				];
			}
			return @result;
		}
	)
}

# Proxy methods

BEGIN {
	for my $method (qw(compose subscribe unsubscribe authorise deauthorise)) {
		my $code = sub { shift->xmpp->$method(@_) };
		{ no strict 'refs'; *{__PACKAGE__ . "::$method"} = $code; }
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
