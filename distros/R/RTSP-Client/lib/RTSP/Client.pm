package RTSP::Client;

use Moose;
use RTSP::Lite;
use Carp qw/croak/;

our $VERSION = '0.4';

=head1 NAME

RTSP::Client - High-level client for the Real-Time Streaming Protocol

=head1 SYNOPSIS

  use RTSP::Client;
  my $client = new RTSP::Client(
      port               => 554,
      client_port_range  => '6970-6971',
      transport_protocol => 'RTP/AVP;unicast',
      address            => '10.0.1.105',
      media_path         => '/mpeg4/media.amp',
  );
  
  # OR
  my $client = RTSP::Client->new_from_uri(uri => 'rtsp://10.0.1.105:554/mpeg4/media.amp');

  $client->open or die $!;
  
  my $sdp = $client->describe;
  my @allowed_public_methods = $client->options_public;

  $client->setup;
  $client->reset;
  
  $client->play;
  $client->pause;
  
  
  $client->teardown;
  
  
=head1 DESCRIPTION

This module provides a high-level interface for communicating with an RTSP server.
RTSP is a protocol for controlling streaming applications, it is not a media transport or a codec. 
It supports describing media streams and controlling playback, and that's about it.

In typical usage, you will open a connection to an RTSP server and send it the PLAY method. The server
will then stream the media at you on the client port range using the specified transport protocol.
You are responsible for listening on the client port range and handling the actual media data yourself,
actually receiving a media stream or decoding it is beyond the scope of RTSP and this module.

=head2 EXPORT

No namespace pollution here!

=head2 ATTRIBUTES

=over 4

=item session_id

RTSP session id. It will be set on a successful OPEN request and added to each subsequent request

=cut
has session_id => (
    is => 'rw',
    isa => 'Str',
);

=item client_port_range

Ports the client receives data on. Listening and receiving data is not handled by RTSP::Client

=cut
has client_port_range => (
    is => 'rw',
    isa => 'Str',
);

=item media_path

Path to the requested media stream

e.g. /mpeg4/media.amp

=cut
has media_path => (
    is => 'rw',
    isa => 'Str',
    default => sub { '/' },
);

=item transport_protocol

Requested transport protocol, RTP by default

=cut
has transport_protocol => (
    is => 'rw',
    isa => 'Str',
    default => sub { 'RTP/AVP;unicast' },
);

=item address

RTSP server address. This is required.

=cut
has address => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

=item port

RTSP server port. Defaults to 554

=cut
has port => (
    is => 'rw',
    isa => 'Int',
    default => sub { 554 },
);

=item connected

Is the client connected?

=cut
has connected => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 },
);

=item print_headers

Print out debug headers

=cut
has print_headers => (
    is => 'rw',
    isa => 'Bool',
);

has have_set_session_header => (
    is => 'rw',
    isa => 'Bool',
);

=item debug

Print debugging information (request status)

=cut
has debug => (
    is => 'rw',
    isa => 'Bool',
);

# RTSP::Lite client
has _rtsp => (
    is => 'rw',
    isa => 'RTSP::Lite',
    default => sub { RTSP::Lite->new },
    handles => [qw/
                    body headers_array headers_string get_header user_agent get_header
                    delete_req_header get_req_header add_req_header status
                /],
);

=back

=head1 METHODS

=over 4

=cut

# construct uri to media
sub _request_uri {
    my ($self) = @_;
    return "rtsp://" . $self->address . ':' . $self->port . $self->media_path;
}

=item open

This method opens a connection to the RTSP server. Returns true on success, false with $! possibly set on failure.

=cut
sub open {
    my ($self) = @_;
    
    # open connection, returns $! set on failure
    my $connected = $self->_rtsp->open($self->address, $self->port);
        
    $self->connected($connected ? 1 : 0);
    return $connected;
}

=item setup

A SETUP request specifies how a single media stream must be transported. This must be done before a PLAY request is sent. The request contains the media stream URL and a transport specifier. This specifier typically includes a local port for receiving RTP data (audio or video), and another for RTCP data (meta information). The server reply usually confirms the chosen parameters, and fills in the missing parts, such as the server's chosen ports. Each media stream must be configured using SETUP before an aggregate play request may be sent.

=cut
sub setup {
    my ($self) = @_;
    
    # request transport
    my $proto = $self->transport_protocol;
    my $ports = $self->client_port_range;
    if ($ports) {
        my $transport_req_str = join(';', $proto, "client_port=$ports");
        $self->_rtsp->add_req_header("Transport", $transport_req_str);
    } elsif (! $self->get_req_header('Transport')) {
        warn "no Transport header set in setup()";
    }

    return unless $self->request('SETUP');
        
    # get session ID
    my $se = $self->_rtsp->get_header("Session");
    my $session = @$se[0];
    
    if ($session) {
        $self->session_id($session);
        $self->add_session_header;
    }
    
    return $session ? 1 : 0; 
}

sub add_session_header {
    my ($self) = @_;
    
    return if $self->have_set_session_header;
    $self->have_set_session_header(1);
    
    $self->add_req_header("Session", $self->session_id)
        if $self->session_id && ! $self->get_req_header('Session');
}

=item new_from_uri(%opts)

Takes same opts as new() and adds additional param: uri

e.g. C<my $rtsp_client = RTSP::Client-E<gt>new_from_uri(uri =E<gt> 'rtsp://10.0.1.105:554/mpeg4/media.amp', debug =E<gt> 1);>

=cut
sub new_from_uri {
    my ($class, %opts) = @_;
    
    my $uri = delete $opts{uri}
        or croak "No URI passed to RTSP::Client::new_from_uri()";
    
    # todo: parse auth
    my ($host, $port, $media_path) = $uri =~ m!^rtsp://([-\w.]+):?(\d+)?(/.+)?$!ism;

    unless ($host) {
        croak "Invalid RTSP URI '$uri' passed to RTSP::Client::new_from_uri()";
    }
    
    $opts{address} ||= $host;
    $opts{port} ||= $port if $port;
    $opts{media_path} ||= $media_path if $media_path;
    
    return $class->new(%opts);
}

=item play

A PLAY request will cause one or all media streams to be played. Play requests can be stacked by sending multiple PLAY requests. The URL may be the aggregate URL (to play all media streams), or a single media stream URL (to play only that stream). A range can be specified. If no range is specified, the stream is played from the beginning and plays to the end, or, if the stream is paused, it is resumed at the point it was paused.

=cut
sub play {
    my ($self) = @_;
    $self->add_session_header;
    return $self->request('PLAY');
}

=item pause

A PAUSE request temporarily halts one or all media streams, so it can later be resumed with a PLAY request. The request contains an aggregate or media stream URL.

=cut
sub pause {
    my ($self) = @_;
    $self->add_session_header;
    return $self->request('PAUSE');
}

=item record

The RECORD request can be used to send a stream to the server for storage.

=cut
sub record {
    my ($self) = @_;
    $self->add_session_header;
    return $self->request('RECORD');
}

=item teardown

A TEARDOWN request is used to terminate the session. It stops all media streams and frees all session related data on the server.

=cut
sub teardown {
    my ($self) = @_;
    $self->add_session_header;
    return $self->request('TEARDOWN');
    $self->connected(0);
    $self->reset;
}

sub options {
    my ($self, $uri) = @_;
    return $self->request('OPTIONS');
}

=item options_public

An OPTIONS request returns the request types the server will accept.

This returns an array of allowed public methods.

=cut
sub options_public {
    my ($self) = @_;
    return unless $self->options;
    my $public = $self->_rtsp->get_header('Public');
    return $public ? @$public : undef;
}

=item describe

The reply to a DESCRIBE request includes the presentation description, typically in Session Description Protocol (SDP) format. Among other things, the presentation description lists the media streams controlled with the aggregate URL. In the typical case, there is one media stream each for audio and video.

This method returns the actual DESCRIBE content, as SDP data

=cut
sub describe {
    my ($self) = @_;
    return unless $self->request('DESCRIBE');
    return $self->body;
}

=item request($method)

Sends a $method request, returns true on success, false with $! possibly set on failure

=cut
sub request {
    my ($self, $method, $uri) = @_;
    
    # make sure we're connected
    unless ($self->connected) {
        $self->open or return;
    }
        
    $self->_rtsp->method(uc $method);
    
    # request media
    my $req_uri = $uri || $self->_request_uri;
    $self->_rtsp->request($req_uri)
        or return;
        
    # request status
    my $status = $self->_rtsp->status;
    if ($self->debug) {
        print STDERR "Status: $status " . $self->_rtsp->status_message . "\n";
    }
    if (! $status || $status != 200) {
        return;
    }
    
    if ($self->print_headers) {
        my @headers = $self->_rtsp->headers_array;
        my $body = $self->_rtsp->body;
        print STDERR "$_\n" foreach @headers;
        print STDERR "$body\n" if $body;
    }
    
    return 1;
}

# clean up connection if we're still connected
sub DEMOLISH {
    my ($self) = @_;
    
    $self->reset;
    return unless $self->connected;
    #$self->teardown;
    
}

=item reset

If you wish to reuse the client for multiple requests, you should call reset after each request unless you want to keep the socket open.

=cut
sub reset {
    my ($self) = @_;
    
    $self->_rtsp->reset;
}


=item status_message

Get the status message of the last request (e.g. "Bad Request")

=cut
sub status_message {
    my ($self) = @_;
    my $msg = $self->_rtsp->status_message || '';
    $msg =~ s/(\r\n)$//sm;
    return $msg;
}

#### these are handled by RTSP::Lite

=item status

Get the status code of the last request (e.g. 200, 405)

=item get_header ($header)

returns response header

=item add_req_header ($header, $value)

=item get_req_header ($header)

=item delete_req_header ($header)

=cut



no Moose;
__PACKAGE__->meta->make_immutable;

=back

=head1 SEE ALSO

L<RTSP::Lite>, L<http://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol>

=head1 AUTHOR

Mischa Spiegelmock E<lt>revmischa@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

This is based entirely on L<RTSP::Lite> by Masaaki Nabeshima.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
