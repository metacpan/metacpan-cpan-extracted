package Net::Async::SMTP::Client;
$Net::Async::SMTP::Client::VERSION = '0.002';
use strict;
use warnings;
use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::SMTP::Client - sending email with IO::Async

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use IO::Async::Loop;
 use Net::Async::SMTP::Client;
 use Email::Simple;
 my $email = Email::Simple->create(
 	header => [
 		From    => 'someone@example.com',
 		To      => 'other@example.com',
 		Subject => 'NaSMTP test',
 	],
 	attributes => {
 		encoding => "8bitmime",
 		charset  => "UTF-8",
 	},
 	body_str => '... text ...',
 );
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $smtp = Net::Async::SMTP::Client->new(
 		domain => 'example.com',
 	)
 );
 $smtp->connected->then(sub {
 	$smtp->login(
 		user => '...',
 		pass => '...',
 	)
 })->then(sub {
 	$smtp->send(
 		to   => 'someone@example.com',
 		from => 'other@example.com',
 		data => $email->as_string,
 	)
 })->get;

=head1 DESCRIPTION

Provides basic email sending capability for L<IO::Async>, using
the L<Protocol::SMTP> implementation.

See L<Protocol::SMTP/DESCRIPTION> for a list of supported features
and usage instructions.

=cut

use IO::Async::Resolver::DNS;
use Future::Utils qw(try_repeat_until_success);

use Net::Async::SMTP::Connection;

=head1 METHODS

=head2 connection

Establishes or returns the TCP connection to the SMTP server.

=over 4

=item * If we had a host, we'll connect directly.

=item * If we have a domain, then we'll do an MX lookup on it.

=item * If we don't have either, you'll probably just see errors
or unresolved futures.

=back

Returns the L<Future> representing the connection. Attach events via
methods on L<Future> such as C<on_done>, C<then> etc.

See also: L</connected>

=cut

sub connection {
	my $self = shift;
	(defined($self->host)
	? Future->wrap($self->host)
	: $self->mx_lookup($self->domain))->then(sub {
		my @hosts = @_;
		try_repeat_until_success {
			my $host = shift;
			$self->debug_printf("Trying connection to [%s]", $host);
			$self->loop->connect(
				socktype => 'stream',
				host     => $host,
				service  => $self->port || 'smtp',
			)->on_fail(sub {
				$self->debug_printf("Failed connection to [%s], have %d left to try", $host, scalar @hosts);
			})
		} foreach => \@hosts;
	});
}

=head2 mx_lookup

Looks up MX records for the given domain.

Returns a L<Future> which will resolve to the list of records found.

=cut

sub mx_lookup {
	my $self = shift;
	my $domain = shift;
	my $resolver = $self->loop->resolver;

 	# Wrap the resolver query as a Future
 	my $f = $self->loop->new_future;
	$resolver->res_query(
		dname => $domain,
		type  => "MX",
		on_resolved => sub {
			$f->done(@_);
			undef $f;
		},
		on_error => sub {
			$f->fail(@_);
			undef $f;
		},
	);

	# ... and return just the list of hosts we want to contact as our result
	$f->transform(
		done => sub {
			my $pkt = shift;
			my @host;
			foreach my $mx ( $pkt->answer ) {
				next unless $mx->type eq "MX";
				push @host, [ $mx->preference, $mx->exchange ];
			}
			# sort things - possibly already handled by the resolver
			map $_->[1], sort { $_->[0] <=> $_->[1] } @host;
		}
	);
}

=head2 configure

Overrides L<IO::Async::Notifier> C<configure> to apply SMTP-specific config.

=cut

sub configure {
	my $self = shift;
	my %args = @_;
	for(grep exists $args{$_}, qw(host user pass auth domain)) {
		$self->{$_} = delete $args{$_};
	}
	# SSL support
	$self->{$_} = delete $args{$_} for grep /^SSL_/, keys %args;
	$self->SUPER::configure(%args);
}

=head2 connected

Returns the L<Future> indicating our SMTP connection.

Resolves to a L<Net::Async::SMTP::Connection> instance on
success.

=cut

sub connected {
	my $self = shift;
	$self->{connected} ||= $self->connection->then(sub {
		my $sock = shift;
		my $stream = Net::Async::SMTP::Connection->new(
			handle => $sock,
			$self->auth
			? (auth => $self->auth)
			: (),
		);
		$self->add_child($stream);
		$stream->send_greeting->then(sub {
			return Future->wrap($stream) unless $stream->has_feature('STARTTLS');

			# Currently need to have this loaded to find ->sslwrite
			require IO::Async::SSLStream;

			$stream->starttls(
				$self->ssl_parameters
			)
		});
	});
}

=head2 ssl_parameters

Returns any defined SSL parameters as passed to the constructor
or L</configure>.

=cut

sub ssl_parameters {
	my $self = shift;
	map { $_, $self->{$_} } grep /^SSL_/, keys %$self;
}

=head2 login

Attempts login, connecting first if required.

Returns a L<Future> which will resolve with this instance when the login completes.

=cut

sub login {
	my $self = shift;
	my %args = @_;
	$self->connected->then(sub {
		my $connection = shift;
		$connection->login(%args);
	});
}

=head2 send

Attempts to send message(s), connecting first if required.

If this server requires login, you'll need to call L</login> yourself.

See L<Protocol::SMTP::Client/send>.

Returns a L<Future>.

=cut

sub send {
	my $self = shift;
	my %args = @_;

	$self->connected->then(sub {
		my $connection = shift;
		$connection->send(%args);
	})
}

=head1 METHODS - Accessors

=cut

=head2 port

Returns the port used for communicating with the server,
or undef for default (25).

=cut

sub port { shift->{port} }

=head2 host

Returns the host we're going to connect to.

=cut

sub host { shift->{host} }

=head2 domain

Returns the domain used for the email server.

=cut

sub domain { shift->{domain} }

=head2 auth

Returns the auth method used for server authentication.

=cut

sub auth { shift->{auth} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
