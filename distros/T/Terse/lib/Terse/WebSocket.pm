package Terse::WebSocket;

use base 'Terse';
use MIME::Base64;

sub new {
	my ($class, $t) = @_;
	my $self = $class->SUPER::new();
	my $version = '';
	my $env =  $t->request->env; 
	if (!$env->{$t->{_sock}} || !$env->{$t->{_stream_check}}) {
		return 'Invalid environment no _sock or _stream_check in env';
	}
	$self->options = {
		secret => 'ABABCABC-ABC-ABC-ABCD-ABCABCABCABC',
		upgrade    => $env->{HTTP_UPGRADE},
		connection => $env->{HTTP_CONNECTION},
		host       => $env->{HTTP_HOST},
		origin => $env->{HTTP_ORIGIN},
		($env->{HTTP_SEC_WEBSOCKET_KEY} 
			? (sec_websocket_key => $env->{HTTP_SEC_WEBSOCKET_KEY})
			: ()
		),
		($env->{HTTP_SEC_WEBSOCKET_KEY1}
			? (sec_websocket_key1 => $env->{HTTP_SEC_WEBSOCKET_KEY1})
			: (sec_websocket_key2 => $env->{HTTP_SEC_WEBSOCKET_KEY2})
		),
		subprotocol => 'chat',
    	};
	if (exists $env->{HTTP_SEC_WEBSOCKET_VERSION}) {
		$fields->{'sec_websocket_version'} = $env->{HTTP_SEC_WEBSOCKET_VERSION};
		if ($env->{HTTP_SEC_WEBSOCKET_VERSION} eq '13') {
            		$self->version = 'draft-ietf-hybi-17';
        	}
       		else {
            		$self->version = 'draft-ietf-hybi-10';
        	}
    	}
	$self->resource_name = "$env->{SCRIPT_NAME}$env->{PATH_INFO}"
		  . ($env->{QUERY_STRING} ? "?$env->{QUERY_STRING}" : "");
	$self->psgix = $env->{'psgix.io'}; 
	if ($env->{HTTP_X_FORWARDED_PROTO} && $env->{HTTP_X_FORWARDED_PROTO} eq 'https') {
		$self->secure(1);
	}
	unless ($self->parse($_[0])) {
		$self->error($req->error);
		return;
	}
	return $self;
}

sub start {
	my ($self, $t, $cbs, $responder) = @_; 
	my $writer = eval { $responder->([101, [$self->headers]]); };
	$cbs->{($@ ? 'error' : 'connect')}->($self, $responder, $@);
	my $reset_rate = $t->websocket_reset_rate ||= 100000;
	eval {
		my $ping_rate = $reset_rate;
		while (1) {
			$ping_rate--;
			my $response;
			if ($ping_rate < 0) {
				$ping_rate = $reset_rate;
				$self->send($ping);
				$response = $self->recieve() while($ping_rate-- > 0 && !$response);
				if (!$response || $response ne 'pong') {
					last;
				}
				$ping_rate = $reset_rate;
			}
			$response = $self->recieve();
			if ($response) {
				if ($response =~ m/^invalid_(length|version|host|required_key)$/) {
					$cbs->{error}->($self, $response, $responder);
					last;
				} else {
					$ping_rate = $reset_rate;
					$cbs->{recieve}->($self, $response, $responder);
				}
			}
		}
	};
	$cbs->{error}->($self, $responder, $@) if ($@);
	$cbs->{disconnect}->($self, $responder) if $cbs->{disconnect};
	delete $t->{_application}->websockets->{$t->sid->value} if $cbs->{close_delete};
	$responder->([200, []]);
}

sub headers {
	my ($self) = @_;
	my $version = $self->version || 'draft-ietf-hybi-10';
	my @headers = ();
	push @headers, Upgrade => 'WebSocket';
	push @headers, Connection => 'Upgrade';
	if ($version eq 'draft-hixie-75' || $version eq 'draft-ietf-hybi-00') {
        	return 'invalid_host' unless defined $self->options->host;
		my $location = 'ws';
    		$location .= 's' if $self->options->secure;
    		$location .= '://';
    		$location .= $self->options->host;
    		$location .= ':' . $self->options->port if defined $self->options->port;
    		$location .= $self->resource_name || '/';
        	my $origin = $self->options->origin ? $self->options->origin : 'http://' . $self->options->host;
        	$origin =~ s{^http:}{https:} if !$self->options->origin && $self->options->secure;
		if ($version eq 'draft-hixie-75') {
            		push @headers, 'WebSocket-Protocol' => $self->subprotocol
              			if defined $self->options->subprotocol;
            		push @headers, 'WebSocket-Origin'   => $origin;
           	 	push @headers, 'WebSocket-Location' => $location;
        	}
        	elsif ($version eq 'draft-ietf-hybi-00') {
            		push @headers, 'Sec-WebSocket-Protocol' => $self->options->subprotocol
              			if defined $self->options->subprotocol;
            		push @headers, 'Sec-WebSocket-Origin'   => $origin;
            		push @headers, 'Sec-WebSocket-Location' => $location;
        	}
    	}
	elsif ($version eq 'draft-ietf-hybi-10' || $version eq 'draft-ietf-hybi-17') {
        	return 'invalid_required_key' unless defined $self->options->key;
        	my $key = $self->options->key;
        	$key .= $self->options->secret;
        	$key = Digest::SHA::sha1($key);
        	$key = MIME::Base64::encode_base64($key);
        	$key =~ s{\s+}{}g;
        	push @headers, 'Sec-WebSocket-Accept' => $key;
        	push @headers, 'Sec-WebSocket-Protocol' => $self->options->subprotocol
          		if defined $self->options->subprotocol;
    	}
    	else {
		return 'invalid_version';
    	}
	return @headers;
}

sub send {
	my ($self, $message) = @_;
	my $pg = $self->psgix;
	my $mask = $self->mask ||= 0;
	my (@ENCODED) = map { ord($_) } split //, $message;
	my $length = scalar @ENCODED + 128;
	if ($length > 254 || $mask) {
		@MASK = map { int(rand(256)) } 0 .. 3;
		my $i;
		$ENCODED[$i++] = $_ ^ $MASK[$i % 4] for (@ENCODED);
		unshift @ENCODED, @MASK;
		if ($length > 256) {
			my $times = int(($length + 2) / 254) - 1;
			my $excess = $length - (($times * 256) + 128);
			unshift @ENCODED, (254, $times, $excess);
		} else {
			unshift @ENCODED, $length;
		}
	} else {
		unshift @ENCODED, $length - 128;
	}
	syswrite $pg, join("", map {chr($_)} (129,  @ENCODED));
	return $self;
}

sub recieve {
	my ($self, @ENCODED) = @_;
	my $length;
	if (! scalar @ENCODED ) {
		return shift @{ $self->next_frame } if scalar @{ $self->next_frame ||= [] }; 
		my $pg = $self->psgix;
		my $content = "";
		$length = sysread($pg, $content, 8192);
		return unless $length;
		$length = sysread($pg, $content, 8192, length($content)) while $length >= 8192;
		@ENCODED = map { unpack "C", $_ } split //, $content;
	}
	my @bits = split //, sprintf("%b\n", $ENCODED[0]);
        $self->fin = $bits[0];
        $self->rsv = [@bits[1 .. 3]];
	$self->op = shift @ENCODED;
	if ($ENCODED[0] == 254) {
		my @length = splice @ENCODED, 0, 3;
		$length = ((($length[0] + 2) * $length[1]) + $length[2]);
	} else {
		$length = shift @ENCODED;
		$length -= 128;
	}
	return pack "C*", join("", @ENCODED) if (scalar @ENCODED == $length);
	my @MASK = splice @ENCODED, 0, 4;
	if (scalar @ENCODED > $length) {
		my $next = $self->recieve(splice @ENCODED, $length, scalar @ENCODED);
		return $next if ($next eq 'invalid_length');
		unshift @{ $self->next_frame }, $next;
	}
	return 'invalid_length' if (scalar @ENCODED != $length);
	return join "", map { pack "C", ($ENCODED[$_] ^ $MASK[$_ % 4]) } 0 .. $#ENCODED;
}

1;

__END__;


=head1 NAME

Terse::WebSocket - Lightweight WebSockets

=head1 VERSION

Version 0.121

=cut

=head1 SYNOPSIS

	package Chat;

	use base 'Terse';

	sub auth {
		my ($self, $t, $session) = @_;
		return 0 if $t->params->not;
		return $session;
	}

	sub chat {
		my ($self, $t) = @_;
		$self->webchat->{$t->sid->value} = $t->websocket(
			connect => sub {
				my ($websocket) = @_;
				$websocket->send('Hello');
			},
			recieve => sub {
				my ($websocket, $message) = @_;

				$websocket->send($message); # echo
			},
			error => sub { ... },
			disconnect => sub { ... }
		);
	}

	1;

	plackup -s Starman Chat.psgi

	CONNECT ws://localhost:5000?req=chat;


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

L<Terse>.

=cut
