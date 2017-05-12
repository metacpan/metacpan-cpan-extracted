#!/usr/bin/env perl

# Minimal WebSocket application for browser testing. Based on example from
# Mojolicious distribution.

use FindBin ();

use lib $FindBin::Bin . '/../lib';

BEGIN {
	use Mojo::Transaction::HTTP ();
	use MojoX::Transaction::WebSocket76 ();

	# Override Mojo::Transaction::HTTP::server_read().
	*Mojo::Transaction::HTTP::server_read = sub {
		my ($self, $chunk) = @_;

		# Parse
		my $req = $self->req;
		$req->parse($chunk) unless $req->error;
		$self->{state} ||= 'read';

		# Parser error
		my $res = $self->res;
		if ($req->error && !$self->{handled}++) {
			$self->emit('request');
			$res->headers->connection('close');
		}

		# EOF
		elsif ((length $chunk == 0) || ($req->is_finished && !$self->{handled}++)) {
			if (lc($req->headers->upgrade || '') eq 'websocket') {
				# Upgrade to WebSocket of needed version.
				$self->emit(upgrade =>
					  ($req->headers->header('Sec-WebSocket-Key1')
					&& $req->headers->header('Sec-WebSocket-Key2'))
						? MojoX::Transaction::WebSocket76->new(handshake => $self)
						: Mojo::Transaction::WebSocket->new(handshake => $self)
				);
			}
			$self->emit('request');
		}

		# Expect 100 Continue
		elsif ($req->content->is_parsing_body && !defined $self->{continued}) {
			if (($req->headers->expect || '') =~ /100-continue/i) {
				$self->{state} = 'write';
				$res->code(100);
				$self->{continued} = 0;
			}
		}
	};
}

use Mojolicious::Lite;


any '/' => sub {
	my $self = $_[0];

	$self->on(message => sub {
		$_[0]->send($_[1])
	}) if $self->tx->is_websocket;
} => 'websocket';

app->start();


__DATA__

@@ websocket.html.ep
<!DOCTYPE html>
<html>
	<head>
		<title>WebSocket</title>
%	my $url = url_for->to_abs->scheme('ws');
%=	javascript begin
	var ws;
	if ('MozWebSocket' in window) {
		ws = new MozWebSocket('<%= $url %>');
	}
	else if ('WebSocket' in window) {
		ws = new WebSocket('<%= $url %>');
	}
	if(typeof(ws) !== 'undefined') {
		ws.onmessage = function (event) {
			alert(event.data);
		}
		ws.onopen = function (event) {
			ws.send('WebSocket support works!');
		}
	}
	else {
		alert('Sorry, your browser does not support WebSockets.');
	}
%	end
	</head>
	<body>
		<p>Testing WebSockets, please make sure you have JavaScript enabled.</p>
	</body>
</html>
