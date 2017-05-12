package Protocol::SPDY::Constants;
$Protocol::SPDY::Constants::VERSION = '1.001';
use strict;
use warnings;
use parent qw(Exporter);

=head1 NAME

Protocol::SPDY::Constants - constant definitions for the SPDY protocol

=head1 VERSION

version 1.001

=head1 SYNOPSIS

 use Protocol::SPDY::Constants ':all';

=head1 DESCRIPTION

Provides some constants.

=head1 CONSTANTS

=head2 FLAG_FIN

Value for the FIN flag in control/data frames.

=head2 FLAG_COMPRESS

Compression flag - currently unused

=head2 FLAG_UNI

Unidirectional flag - used to mark a stream as not requiring a reply.

=head2 HEADER_LENGTH

Number of bytes required in order to work out how big a frame will be.

=head2 ZLIB_DICTIONARY

Initial compression dictionary for the zlib compression protocol used
for name/value pair data.

=head2 MAX_SUPPORTED_VERSION

Highest version we know about.

=head1 RST_STREAM CODES

The following codes can be returned as values in a
L<RST_STREAM|Protocol::SPDY::Frame::Control::RST_STREAM> frame. See
the L<status_code|Protocol::SPDY::Frame::Control::RST_STREAM/status_code>
and L<status_code_as_text|Protocol::SPDY::Frame::Control::RST_STREAM/status_code_as_text>
methods.

=head2 PROTOCOL_ERROR

There was a protocol violation in something we've sent to the other side.

=head2 INVALID_STREAM

The requested stream is not valid (for example, when we receive a reply
to a stream that we did not initiate).

=head2 REFUSED_STREAM

We do not want this stream.

=head2 UNSUPPORTED_VERSION

The protocol version requested is not supported by this library.

=head2 CANCEL

Used by the initiator to stop an active stream before normal completion.

=head2 INTERNAL_ERROR

Generic error when internal state is invalid.

=head2 FLOW_CONTROL_ERROR

We violated the expected window update behaviour.

=cut

use constant {
	# Flag indicating whether this is the final packet in the stream
	FLAG_FIN      => 0x01,
	# Whether compression is enabled
	FLAG_COMPRESS => 0x02,
	# Unidirectional (section 2.3.6)
	FLAG_UNI	  => 0x02,
	# Number of bytes in the header (common between control and data frames)
	HEADER_LENGTH => 8,
	# The spec requires seeding our zlib instance with a specific dictionary to get
	# better performance. Note that the dictionary varies depending on the version
	# of the protocol we're dealing with - this is the spdy/3.1 dictionary:
	ZLIB_DICTIONARY	=> join('',
		(
			# These are all length-prefixed strings, mostly client=>server traffic
			map pack('N/a*', $_), qw(
				options
				head
				post
				put
				delete
				trace
				accept
				accept-charset
				accept-encoding
				accept-language
				accept-ranges
				age
				allow
				authorization
				cache-control
				connection
				content-base
				content-encoding
				content-language
				content-length
				content-location
				content-md5
				content-range
				content-type
				date
				etag
				expect
				expires
				from
				host
				if-match
				if-modified-since
				if-none-match
				if-range
				if-unmodified-since
				last-modified
				location
				max-forwards
				pragma
				proxy-authenticate
				proxy-authorization
				range
				referer
				retry-after
				server
				te
				trailer
				transfer-encoding
				upgrade
				user-agent
				vary
				via
				warning
				www-authenticate
				method
				get
				status
			),
			"200 OK",
			qw(
				version
				HTTP/1.1
				url
				public
				set-cookie
				keep-alive
				origin
			)
		),
		# Now we have some other useful strings - these are mostly server responses, no length prefix
		"100101201202205206300302303304305306307402405406407408409410411412413414415416417502504505",
		"203 Non-Authoritative Information",
		"204 No Content",
		"301 Moved Permanently",
		"400 Bad Request",
		"401 Unauthorized",
		"403 Forbidden",
		"404 Not Found",
		"500 Internal Server Error",
		"501 Not Implemented",
		"503 Service Unavailable",
		"Jan Feb Mar Apr May Jun Jul Aug Sept Oct Nov Dec",
		" 00:00:00",
		" Mon, Tue, Wed, Thu, Fri, Sat, Sun, GMT",
		"chunked,text/html,image/png,image/jpg,image/gif,application/xml,application/xhtml+xml,text/plain,text/javascript,public",
		"privatemax-age=gzip,deflate,sdchcharset=utf-8charset=iso-8859-1,utf-,*,enq=0.",
	),

	# Which version we support
	MAX_SUPPORTED_VERSION => 3,
# SETTINGS packet flags
	# Request to persist settings
	FLAG_SETTINGS_PERSIST_VALUE => 0x01,
	# Inform other side of previously-persisted settings
	FLAG_SETTINGS_PERSISTED => 0x02,
# Status codes for RST_STREAM
	PROTOCOL_ERROR      => 1,
	INVALID_STREAM      => 2,
	REFUSED_STREAM      => 3,
	UNSUPPORTED_VERSION => 4,
	CANCEL              => 5,
	INTERNAL_ERROR      => 6,
	FLOW_CONTROL_ERROR  => 7,

	FRAME_TYPE_BY_ID => {
		1 => 'SYN_STREAM',
		2 => 'SYN_REPLY',
		3 => 'RST_STREAM',
		4 => 'SETTINGS',
		5 => 'NOOP',
		6 => 'PING',
		7 => 'GOAWAY',
		8 => 'HEADERS',
		9 => 'WINDOW_UPDATE',
		10 => 'CREDENTIAL',   # no longer present in 3.1+
	},
	SETTINGS_BY_ID => {
		# Expected upload bandwidth
		1 => 'EXPECTED_UPLOAD_BANDWIDTH',
		# Expected download bandwidth
		2 => 'EXPECTED_DOWNLOAD_BANDWIDTH',
		# How long we expect packets to take to go from here to there and back again
		3 => 'EXPECTED_ROUND_TRIP_TIME',
		# How many streams we want - clients which do not want server push seem to
		# use a 0 value here to disable the feature
		4 => 'MAX_CONCURRENT_STREAMS',
		# TCP initial client window size
		5 => 'CURRENT_CWND',
		# Retransmission rate on downloads (percentage)
		6 => 'DOWNLOAD_RETRANS_RATE',
		# Start with windows of this size (in bytes)
		7 => 'INITIAL_WINDOW_SIZE',
	},
	RST_STATUS_CODE_BY_ID => {
		1 => 'PROTOCOL_ERROR',
		2 => 'INVALID_STREAM',
		3 => 'REFUSED_STREAM',
		4 => 'UNSUPPORTED_VERSION',
		5 => 'CANCEL',
		6 => 'INTERNAL_ERROR',
		7 => 'FLOW_CONTROL_ERROR',
		8 => 'STREAM_IN_USE',
		9 => 'STREAM_ALREADY_CLOSED',
		10 => 'INVALID_CREDENTIALS',
		11 => 'FRAME_TOO_LARGE',
	},
};

# Reversed lookup mappings
use constant {
	FRAME_TYPE_BY_NAME      => +{ reverse %{+FRAME_TYPE_BY_ID} },
	SETTINGS_BY_NAME        => +{ reverse %{+SETTINGS_BY_ID} },
	RST_STATUS_CODE_BY_NAME => +{ reverse %{+RST_STATUS_CODE_BY_ID} },
};

our @EXPORT_OK = qw(
	FLAG_FIN FLAG_COMPRESS FLAG_UNI
	FRAME_TYPE_BY_ID FRAME_TYPE_BY_NAME
	SETTINGS_BY_ID SETTINGS_BY_NAME
	FLAG_SETTINGS_PERSISTED FLAG_SETTINGS_PERSIST_VALUE
	RST_STATUS_CODE_BY_ID RST_STATUS_CODE_BY_NAME
	HEADER_LENGTH
	ZLIB_DICTIONARY MAX_SUPPORTED_VERSION
	PROTOCOL_ERROR INVALID_STREAM REFUSED_STREAM UNSUPPORTED_VERSION
	CANCEL INTERNAL_ERROR FLOW_CONTROL_ERROR
);

our %EXPORT_TAGS = (
	'all'	=> \@EXPORT_OK,
);

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Protocol::SPDY>

=item * L<Protocol::SPDY::Frame>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
