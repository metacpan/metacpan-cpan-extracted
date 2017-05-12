package MojoX::IOLoop::Server::StartTLS;

use IO::Socket::SSL;

# We'll use the version of Mojolicious this was written against
# but we'll add two digits for flexibility
our $VERSION = '5.1401';

use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
our $CERT = catfile dirname(__FILE__), 'server.crt';
our $KEY  = catfile dirname(__FILE__), 'server.key';

#------------------------------------------------------------------------------

sub start_tls {
	my ($server, $stream, $options, $callback) = @_;

	$stream->on(drain => sub {
		my $handle = $stream->steal_handle;

		$stream->handle(IO::Socket::SSL->start_SSL($handle, 
			# Useful defaults
			SSL_cert_file => $CERT,
			SSL_cipher_list => '!aNULL:!eNULL:!EXPORT:!DSS:!DES:!SSLv2:!LOW:RC4-SHA:RC4-MD5:ALL',
			SSL_honor_cipher_order => 1,
			SSL_key_file => $KEY,
			SSL_startHandshake => 0,
			SSL_verify_mode => 0x00,
			SSL_server => 1,
			SSL_error_trap => sub {
				return unless $handle = delete $server->{handles}{$handle};
				$server->reactor->remove($handle);
				close $handle;
			},
			# Mojo defaults
			$server->{tls} ? %{$server->{tls}} : (),
			# User options
			$options ? %$options : (),
		));

		$callback->($handle) if $callback;
		$server->reactor->io($handle => sub { $server->_tls($handle) });
		$server->{handles}{$handle} = $handle;
	});
}

#------------------------------------------------------------------------------

1;
