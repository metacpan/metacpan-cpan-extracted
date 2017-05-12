package Net::Async::UWSGI::Server::Connection;
$Net::Async::UWSGI::Server::Connection::VERSION = '0.006';
use strict;
use warnings;

use parent qw(IO::Async::Stream);

=head1 NAME

Net::Async::UWSGI::Server::Connection - represents an incoming connection to a server

=head1 VERSION

version 0.006

=head1 DESCRIPTION

=cut

use JSON::MaybeXS;

use URI::QueryParam;
use IO::Async::Timer::Countdown;

use Encode qw(encode);
use Protocol::UWSGI qw(:server);
use List::UtilsBy qw(bundle_by);

=head2 CONTENT_TYPE_HANDLER

=cut

our %CONTENT_TYPE_HANDLER = (
	'application/javascript' => 'json',
);

use constant USE_HTTP_RESPONSE => 0;

=head1 METHODS

=cut

=head2 configure

Applies configuration parameters.

=over 4

=item * bus - the event bus

=item * on_request - callback when we get an incoming request

=back

=cut

sub configure {
	my ($self, %args) = @_;
	for(qw(bus on_request default_content_handler)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->SUPER::configure(%args);
}

sub default_content_handler { shift->{default_content_handler} }

=head2 json

Accessor for the current JSON state

=cut

sub json { shift->{json} ||= JSON::MaybeXS->new(utf8 => 1) }

=head2 on_read

Base read handler for incoming traffic.

Attempts to delegate to L</dispatch_request> as soon as we get the UWSGI
frame.

=cut

sub on_read {
	my ( $self, $buffref, $eof ) = @_;
	if(my $pkt = extract_frame($buffref)) {
		$self->{env} = $pkt;
		# We have a request, start processing
		return $self->can('dispatch_request');
	} elsif($eof) {
		# EOF before a valid request? Bail out immediately
		$self->cancel;
	}
	return 0;
}

=head2 cancel

Cancels any request in progress.

If there's still a connection to the client,
they'll receive a 500 response.

It's far more likely that the client has gone
away, in which case there's no response to send.

=cut

sub cancel {
	my ($self) = @_;
	$self->response->cancel unless $self->response->is_ready
}

=head2 env

Accessor for the UWSGI environment.

=cut

sub env { shift->{env} }

=head2 response

Resolves when the response is complete.

=cut

sub response {
	$_[0]->{response} ||= $_[0]->loop->new_future;
}

=head2 dispatch_request

At this point we have a request including headers,
and we should know whether there's a body involved
somewhere.

=cut

sub dispatch_request {
	my ($self, $buffref, $eof) = @_;

	# Plain GET request? We might be able to bail out here
	return $self->finish_request unless $self->has_body;

	my $env = $self->env;
	my $handler = $self->default_content_handler || 'raw';
	if(my $type = $env->{CONTENT_TYPE}) {
		$handler = $CONTENT_TYPE_HANDLER{$type} if exists $CONTENT_TYPE_HANDLER{$type};
	}
	$handler = 'content_handler_' . $handler;
	$self->{input_handler} = $self->${\"curry::weak::$handler"};

	# Try to read N bytes if we have content length. Most UWSGI implementations seem
	# to set this.
	if(exists $env->{CONTENT_LENGTH}) {
		$self->{remaining} = $env->{CONTENT_LENGTH};
		return $self->can('read_to_length');
	}

	# Streaming might be nice, but nginx has no support for this
	if(exists $env->{HTTP_TRANSFER_ENCODING} && $env->{HTTP_TRANSFER_ENCODING} eq 'chunked') {
		return $self->can('read_chunked');
	}
	die "no idea how to handle this, missing length and not chunked";
}

sub finish_request {
	my ($self) = @_;
	$self->{request_body} = $self->{input_handler}->()
		if $self->has_body;
	$self->{completion} = $self->{on_request}->($self)
	 ->then($self->curry::write_response)
	 ->on_fail(sub {
	 	$self->debug_printf("Failed while attempting to handle request: %s (%s)", @_);
	})->on_ready($self->curry::close_now);
	return sub {
		my ($self, $buffref, $eof) = @_;
		$self->{completion}->cancel if $eof && !$self->{completion}->is_ready;
		0
	}
}

{
my %methods_with_body = (
	PUT  => 1,
	POST => 1,
	PROPPATCH => 1,
);

=head2 has_body

Returns true if we're expecting a request body
for the current request method.

=cut

sub has_body {
	my ($self, $env) = @_;
	return 1 if $methods_with_body{$self->env->{REQUEST_METHOD}};
	return 0;
}
}

=head2 read_chunked

Read handler for chunked data. Unlikely to be used by any real implementations.

=cut

sub read_chunked {
	my ($self, $buffref, $eof) = @_;
	$self->debug_printf("Body read: $self, $buffref, $eof: [%s]", $$buffref);
	if(defined $self->{chunk_remaining}) {
		my $data = substr $$buffref, 0, $self->{chunk_remaining}, '';
		$self->{chunk_remaining} -= length $data;
		$self->debug_printf("Had %d bytes, %d left in chunk", length($data), $self->{chunk_remaining});
		$self->{input_handler}->($data);
		return 0 if $self->{chunk_remaining};
		$self->debug_printf("Look for next chunk");
		delete $self->{chunk_remaining};
		return 1;
	} else {
		return 0 if -1 == (my $size_len = index($$buffref, "\x0D\x0A"));
		$self->{chunk_remaining} = hex substr $$buffref, 0, $size_len, '';
		substr $$buffref, 0, 2, '';
		$self->debug_printf("Have %d bytes in this chunk", $self->{chunk_remaining});
		return 1 if $self->{chunk_remaining};
		$self->debug_printf("End of chunked data, looking for trailing headers");
		return $self->can('on_trailing_header');
	}
}

=head2 on_trailing_header

Deal with trailing headers. Not yet implemented.

=cut

sub on_trailing_header {
	my ($self, $buffref, $eof) = @_;
	# FIXME not yet implemented
	$$buffref = '';
	return $self->finish_request;
}

=head2 read_to_length

Read up to the expected fixed length of data.

=cut

sub read_to_length {
	my ($self, $buffref, $eof) = @_;
	$self->{remaining} -= length $$buffref;
	$self->debug_printf("Body read: $self, $buffref, $eof: %s with %d remaining", $$buffref, $self->{remaining});
	$self->{input_handler}->($$buffref);
	$$buffref = '';
	return $self->finish_request unless $self->{remaining};
	return 0;
}

=head2 request_body

Accessor for the request body, available to the L</finish_request> callback.

=cut

sub request_body { shift->{request_body} }

sub content_handler_raw {
	my ($self, $data) = @_;
	if(defined $data) {
		$self->{data} .= $data;
	} else {
		return $self->{data}
	}
}

=head2 content_handler_json

Handle JSON content.

=cut

sub content_handler_json {
	my ($self, $data) = @_;
	if(defined $data) {
		eval {
			$self->json->incr_parse($data);
			1
		} or do {
			$self->debug_printf("Invalid JSON received: %s", $@);
		};
	} else {
		return eval {
			$self->json->incr_parse
		} // do {
			$self->debug_printf("Invalid JSON from incr_parse: %s", $@);
		}
	}
}

my %status = (
	100 => 'Continue',
	101 => 'Switching protocols',
	102 => 'Processing',
	200 => 'OK',
	201 => 'Created',
	202 => 'Accepted',
	203 => 'Non-authoritative information',
	204 => 'No content',
	205 => 'Reset content',
	206 => 'Partial content',
	207 => 'Multi-status',
	208 => 'Already reported',
	226 => 'IM used',
	300 => 'Multiple choices',
	301 => 'Moved permanently',
	302 => 'Found',
	303 => 'See other',
	304 => 'Not modified',
	305 => 'Use proxy',
	307 => 'Temporary redirect',
	308 => 'Permanent redirect',
	400 => 'Bad request',
	401 => 'Unauthorised',
	402 => 'Payment required',
	403 => 'Forbidden',
	404 => 'Not found',
	405 => 'Method not allowed',
	500 => 'Internal server error',
);

sub write_response {
	my ($self, $code, $hdr, $body) = @_;
	my $type = ref($body) ? 'text/javascript' : 'text/plain';
	my $content = ref($body) ? encode_json($body) : encode(
		'UTF-8' => $body
	);
	$hdr ||= [];
	if(USE_HTTP_RESPONSE) {
		return $self->write(
			'HTTP/1.1 ' . HTTP::Response->new(
				$code => ($status{$code} // 'Unknown'), [
					'Content-Type' => $type,
					'Content-Length' => length $content,
					@$hdr
				],
				$content
			)->as_string("\x0D\x0A")
		)
	} else {
		return $self->write(
			join "\015\012", (
				'HTTP/1.1 ' . $code . ' ' . ($status{$code} // 'Unknown'),
				'Content-Type: ' . $type,
				'Content-Length: ' . length($content),
				(bundle_by { join ': ', @_ } 2, @$hdr),
				'',
				$content
			)
		)
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
