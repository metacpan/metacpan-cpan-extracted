package PEF::Front::WebSocket;
use AnyEvent;
use Coro;
use Coro::AnyEvent;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Compress::Raw::Zlib qw(Z_SYNC_FLUSH Z_OK Z_STREAM_END);
use PEF::Front v0.09;
use PEF::Front::Route;
use PEF::Front::Config;
use PEF::Front::Response;
use PEF::Front::NLS;
use PEF::Front::WebSocket::Base;
use PEF::Front::WebSocket::QueueClient;
use CBOR::XS;
use Errno;

use warnings;
use strict;

our $VERSION = "0.06";
use Data::Dumper;

my $server_slave;
my $server_client;
my $server_client_pid;

my %config = (
	heartbeat_interval         => 30,
	max_payload_size           => 262144,
	deflate_minimum_size       => 96,
	deflate_window_bits        => 12,
	deflate_memory_level       => 5,
	queue_server_port          => cfg_project_dir() . "/var/cache/websocket_queue_server.sock",
	queue_server_address       => "unix/",
	queue_no_client_expiration => 900,
	queue_message_expiration   => 3600,
	queue_reload_message       => {result => 'RELOAD'},
);

BEGIN {
	PEF::Front::Route::add_prefix_handler('ws', \&handler);
	for my $cfg_key (keys %config) {
		my $ref = "PEF::Front::Config"->can("cfg_websocket_" . $cfg_key);
		$config{$cfg_key} = $ref->() if $ref;
	}
}

sub deflate_minimum_size () {$config{deflate_minimum_size}}

sub import {
	my ($package, @args) = @_;
	if (grep {$_ eq "queue_server"} @args) {
		if (!$server_slave) {
			require AnyEvent::Fork;
			start_queue_server();
		}
	}
}

sub handler {
	my ($request, $context) = @_;
	my $mrf = $context->{method};
	$mrf =~ s/ ([[:lower:]])/\u$1/g;
	$mrf = ucfirst($mrf);
	my $class = cfg_app_namespace . "WebSocket::$mrf";
	my $websocket;
	eval {
		no strict 'refs';

		if (not %{$class . "::"}) {
			eval "use $class";
			die {
				result      => 'INTERR',
				answer      => 'Websocket class loading error: $1',
				answer_args => $@
				}
				if $@;
			if (not %{$class . "::"}) {
				die {
					result      => 'INTERR',
					answer      => 'Websocket class loading error: $1',
					answer_args => 'wrong class name'
				};
			}
		}
		$websocket = prepare_websocket($class, $request, $context);
	};
	if ($@) {
		my $response = $@;
		$response = {answer => $@} if not ref $response;
		my $http_response = PEF::Front::Response->new(request => $request, status => 500);
		my $args = [];
		$args = $response->{answer_args}
			if exists $response->{answer_args}
			and 'ARRAY' eq ref $response->{answer_args};
		$response->{answer} = msg_get($context->{lang}, $response->{answer}, @$args)->{message};
		$http_response->set_body($response->{answer});
		cfg_log_level_error
			&& $request->logger->(
			{   level   => "error",
				message => "websocket error: $response->{answer}"
			}
			);
		return $http_response->response();
	}
	async {
		setup_websocket($websocket);
	};
	cede;
	return [];
}

sub _hs_to_string {
	my ($hs, $more_headers) = @_;
	my $status = $hs->res->status;
	my $string = '';
	$string .= "HTTP/1.1 $status WebSocket Protocol Handshake\x0d\x0a";
	my $headers = $hs->res->headers;
	push @$headers, @$more_headers
		if $more_headers && ref $more_headers eq 'ARRAY';
	for (my $i = 0; $i < @$headers; $i += 2) {
		my $key   = $headers->[$i];
		my $value = $headers->[$i + 1];
		$string .= "$key: $value\x0d\x0a";
	}
	$string .= "\x0d\x0a";
	$string .= $hs->res->body;
	return $string;
}

sub prepare_websocket {
	my ($class, $request, $context) = @_;
	my $fh = $request->env->{'psgix.io'}
		or die {
		result => 'INTERR',
		answer => "Server doesn't support raw IO"
		};
	my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($request->env);
	$hs->parse($fh)
		or die {
		result => 'INTERR',
		answer => 'Websocket protocol handshake error'
		};
	if (not $class->isa('PEF::Front::WebSocket::Base')) {
		no strict 'refs';
		unshift @{$class . "::ISA"}, 'PEF::Front::WebSocket::Base';
	}
	my $ws = bless {
		_handle    => AnyEvent::Handle->new(fh => $fh),
		_request   => $request,
		_handshake => $hs,
		_context   => $context,
	}, $class;
	my $exts = $request->header('Sec-WebSocket-Extensions');
	$exts = [$exts] if not ref $exts;
	my $is_deflate = 0;
	for my $e (@$exts) {
		if ($e =~ /permessage-deflate/i) {
			$is_deflate = 1;
			last;
		}
	}
	my $more_headers;
	if ($is_deflate
		&& (!$ws->can("no_compression") || !$ws->no_compression))
	{
		$ws->{_deflate} ||= Compress::Raw::Zlib::Deflate->new(
			AppendOutput => 1,
			MemLevel     => $config{deflate_memory_level},
			WindowBits   => -$config{deflate_window_bits},
		);
		$ws->{_inflate} ||= Compress::Raw::Zlib::Inflate->new(WindowBits => -15);
		$more_headers = ['Sec-WebSocket-Extensions', 'permessage-deflate'];
	}
	my $finish_handshake = _hs_to_string($hs, $more_headers);
	$ws->{_handle}->push_write($finish_handshake);
	$ws;
}

sub queue_server_client {
	return if !$server_client || $server_client_pid != $$;
	return $server_client;
}

sub setup_websocket {
	if ($server_slave && !queue_server_client) {
		$server_client = PEF::Front::WebSocket::QueueClient->new(
			address => $config{queue_server_address},
			port    => $config{queue_server_port}
		);
		$server_client_pid = $$;
	}
	no warnings 'redefine';
	*setup_websocket = \&real_setup_websocket;
	goto &real_setup_websocket;
}

sub real_setup_websocket {
	my $ws = $_[0];
	$ws->{_handle}->on_drain(
		sub {
			$ws->{_handle}->on_drain(
				sub {
					$ws->on_drain if delete $ws->{_expected_drain};
				}
			);
			$ws->on_open;
		}
	);
	my $frame = Protocol::WebSocket::Frame->new(max_payload_size => $config{max_payload_size});
	my $on_error = sub {
		my ($handle, $fatal, $message) = @_;
		$ws->{_error} = 1;
		$ws->on_error($message);
	};
	$ws->{_handle}->on_eof($on_error);
	$ws->{_handle}->on_error($on_error);
	$ws->{_handle}->on_timeout(sub { });
	$ws->{_handle}->on_read(
		sub {
			$frame->append($_[0]->rbuf);
			my $message = $frame->next_bytes;
			if ($frame->is_close) {
				$ws->close;
				return;
			}
			if ($frame->is_ping) {
				$ws->{_handle}->push_write(
					Protocol::WebSocket::Frame->new(
						type    => 'pong',
						buffer  => $message,
						version => $ws->{_handshake}->version,
					)->to_bytes
				);
				return;
			}
			if (   $message
				&& $frame->fin
				&& ($frame->is_binary || $frame->is_text))
			{
				if ((my $inflate = $ws->{_inflate}) && $frame->rsv->[0]) {
					my $status = $inflate->inflate(\($message .= "\x00\x00\xff\xff"), my $out);
					if ($status != Z_OK && $status != Z_STREAM_END) {
						cfg_log_level_error
							&& $ws->{_request}->logger->(
							{   level   => "error",
								message => "websocket inflate error"
							}
							);
						$ws->on_error("inflate error");
						return;
					}
					$message = $out;
				}
				my $type = 'binary';
				if ($frame->is_text) {
					utf8::decode($message);
					$type = 'text';
				}
				$ws->on_message($message, $type);
				$message = '';
			}
		}
	);
	$ws->{_heartbeat} = AnyEvent->timer(
		interval => $config{heartbeat_interval},
		cb       => sub {
			if ($ws->{_handle} && !$ws->is_defunct) {
				$ws->{_handle}->push_write(
					Protocol::WebSocket::Frame->new(
						type    => 'ping',
						buffer  => 'ping',
						version => $ws->{_handshake}->version,
					)->to_bytes
				);
			}
		}
	);
	$ws;
}

sub start_queue_server {
	my $cv     = AnyEvent->condvar();
	my $server = AnyEvent::Fork->new->require('PEF::Front::WebSocket::QueueServer')->send_arg(
		$config{queue_server_address},       $config{queue_server_port},
		$config{queue_no_client_expiration}, $config{queue_message_expiration},
		encode_cbor($config{queue_reload_message})
		)->run(
		'PEF::Front::WebSocket::QueueServer::run',
		sub {
			$server_slave = $_[0];
			$cv->send;
		}
		);
	$cv->recv;
	Coro::AnyEvent::readable $server_slave;    # block until child is ready
	read($server_slave, my $buf, 1);
}

1;

__END__

=head1 NAME
 
PEF::Front::WebSocket - WebSocket framework for PEF::Front
 
=head1 SYNOPSIS

    # startup.pl
    use PEF::Front::Websocket;
    # usual startup stuff...

    # $PROJECT_DIR/app/WSTest/WebSocket/Echo.pm
    package WSTest::WebSocket::Echo;
    
    sub on_message {
        my ($self, $message) = @_;
        $self->send($message); 
    }

    1;

=head1 DESCRIPTION
 
This module makes WebSockets really easy. Every kind of WebSocket 
is in its own module. Default routing scheme is C</ws$WebSocketClass>.
WebSocket handlers are located in C<$PROJECT_DIR/app/$MyAPP/WebSocket>.
 
=head2 Prerequisites
 
This module requires L<Coro>, L<AnyEvent> and L<PSGI> server that must 
meet the following requirements.
 
=over
 
=item *
 
C<psgi.streaming> environment is true.
 
=item *
 
C<psgi.nonblocking> environment is true.
 
=item *
 
C<psgix.io> environment holds a valid raw IO socket object. See L<PSGI::Extensions>.
 
=back

L<uwsgi|https://uwsgi-docs.readthedocs.io/en/latest/PSGIquickstart.html> 
version 2.0.14+ meets all of them with C<psgi-enable-psgix-io = true>.
 
=head1 WEBSOCKET INTERFACE METHODS
 
=head2 on_message($message, $type)

A subroutine that is called on new message from client.

=head2 on_drain()
 
A subroutine that is called when there's nothing to send to 
client after some successful send.

=head2 on_open()

A subroutine that is called each time it establishes a new
WebSocket connection to a client.

=head2 on_error($message)

A subroutine that is called when some error
happens while processing a request.

=head2 on_close()
 
A subroutine that is called on WebSocket close event.

=head2 no_compression()

When defined and true then no compression will be used even when it 
supported by browser and server.
 
=head1 INHERITED METHODS

Every WebSocket class is derived from C<PEF::Front::Websocket::Base>
which is derived from C<PEF::Front::Websocket::Interface>. Even when you don't
derive your class from C<PEF::Front::Websocket::Base> explicitly, 
this class will be added automatically to hierarchy.

=head2 send($buffer[, $type])

Sends $buffer to client. By default $type is 'text'.

=head2 close()

Closes WebSocket.

=head2 is_defunct()

Returns true when socket is closed or there's some error on it.

=head1 CONFIGURATION

=over

=item cfg_websocket_heartbeat_interval

WebSocket connection has to be B<ping>-ed to stay alive. 
This paramters specifies a positive number of seconds for B<ping> interval.
Default is 30.

=item cfg_websocket_max_payload_size

Maximum payload size for incoming messages in bytes.
Default is 262144.

=item cfg_websocket_deflate_minimum_size

Minimum message size for deflate compression. If message size is less than
this value then it will not be compressed. Default is 96.

=item cfg_websocket_deflate_window_bits

WindowBits parameter for deflate compression. Default is 12.

=item cfg_websocket_deflate_memory_level

MemLevel parameter for deflate compression. Default is 5.

=back

=head1 EXAMPLE

  #startup.pl
  use WSTest::AppFrontConfig;
  use PEF::Front::Config;
  use PEF::Front::WebSocket;
  use PEF::Front::Route;

  PEF::Front::Route::add_route(
    get '/' => '/appWs',
  );
  PEF::Front::Route->to_app();
  
  
  # $PROJECT_DIR/app/WSTest/WebSocket/Echo.pm
  package WSTest::WebSocket::Echo;
 
  sub on_message {
      my ($self, $message) = @_;
      $self->send($message); 
  }

  1;
  
  # $PROJECT_DIR/templates/ws.html
  <html>
  <head>
  <script language="Javascript">
    var s = new WebSocket("ws://[% hostname %]:[% request.port %]/wsEcho");
    s.onopen = function() {
        alert("connected !!!");
        s.send("ciao");
    };
    s.onmessage = function(e) {
        var bb = document.getElementById('blackboard')
        var html = bb.innerHTML;
        bb.innerHTML = html + '<br/>' + e.data;
    };
    s.onerror = function(e) {
        alert(e);
    }
    s.onclose = function(e) {
        alert("connection closed");
    }
    function invia() {
        var value = document.getElementById('testo').value;
        s.send(value);
    }
  </script>
  </head>
  <body>
    <h1>WebSocket</h1>
    <input type="text" id="testo" />
    <input type="button" value="invia" onClick="invia();" />
    <div id="blackboard"
        style="width: 640px; height: 480px; background-color: black; color: white; border: solid 2px red; overflow: auto">
    </div>
  </body>
  </html>
  
  # wstest.ini
  [uwsgi]
  plugins = coroae
  chdir = /$PROJECT_DIR
  logger = file:log/demo.log
  psgi = bin/startup.pl
  master = true
  processes = 4
  coroae = 1000
  perl-no-plack = true
  psgi-enable-psgix-io = true
  uid = $PROJECT_USER
  gid = www-data
  chmod-socket = 664


=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
