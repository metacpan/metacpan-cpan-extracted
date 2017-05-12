package Net::Lumberjack::Client;

use Moose;

# ABSTRACT: a client for the lumberjack protocol
our $VERSION = '1.02'; # VERSION

use IO::Socket::INET6;
use IO::Socket::SSL;
use Net::Lumberjack::Writer;


has 'host' => ( is => 'ro', isa => 'Str', default => '127.0.0.1' );
has 'port' => ( is => 'ro', isa => 'Int', default => 5044 );
has 'keepalive' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'frame_format' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'max_window_size' => ( is => 'ro', isa => 'Maybe[Int]' );

has '_conn' => ( is => 'rw', isa => 'Maybe[IO::Handle]' );
has '_writer' => ( is => 'rw', isa => 'Maybe[Net::Lumberjack::Writer]' );

has 'use_ssl' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'ssl_verify' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'ssl_ca_file' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_ca_path' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_version' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_hostname' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'ssl_cert' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'ssl_key' => ( is => 'ro', isa => 'Maybe[Str]' );

sub _connect {
  my $self = shift;
  my $sock;
  if( $self->use_ssl ) {
    $sock = IO::Socket::SSL->new(
      PeerHost => $self->host,
      PeerPort => $self->port,
      SSL_verify_mode => $self->ssl_verify ?
        SSL_VERIFY_PEER : SSL_VERIFY_NONE ,
      defined $self->ssl_version ? 
        ( SSL_version => $self->ssl_version ) : (),
      defined $self->ssl_ca_file ? 
        ( SSL_ca_file => $self->ssl_ca_file ) : (),
      defined $self->ssl_ca_path ? 
        ( SSL_ca_file => $self->ssl_ca_path ) : (),
      defined $self->ssl_cert && defined $self->ssl_key ?
        (
          SSL_use_cert => 1,
          SSL_cert_file => $self->ssl_cert,
          SSL_key_file => $self->ssl_key,
        ) : (),
      defined $self->ssl_hostname ?
        ( SSL_hostname => $self->ssl_hostname ) : (),
    ) or die('could not enstablish ssl connection to '.$self->host.':'.$self->port.': '.$SSL_ERROR);
  } else {
    $sock = IO::Socket::INET6->new(
      Proto => 'tcp',
      PeerAddr => $self->host,
      PeerPort => $self->port,
    ) or die('could not connect to '.$self->host.':'.$self->port.': '.$!);
  }
  $self->_conn( $sock );

  my $writer = Net::Lumberjack::Writer->new(
    handle => $sock,
    defined $self->max_window_size ?
      ( max_window_size => $self->max_window_size ) : (),
    defined $self->frame_format ?
      ( frame_format => $self->frame_format ) : (),
  );
  $self->_writer( $writer );

  return;
}

sub _ensure_connected {
  my $self = shift;

  if( defined $self->_conn
      && $self->_conn->connected
      && defined $self->_writer ) {
    return;
  }

  $self->_connect;

  return;
}
sub _reconnect {
  my $self = shift;

  $self->_disconnect;
  $self->_connect;

  return;
}

sub _disconnect {
  my $self = shift;

  if( defined $self->_conn ) {
    $self->_conn->close();
    $self->_conn( undef );
  }
  $self->_writer( undef );

  return;
}

sub send_data {
  my $self = shift;

  $self->_ensure_connected;

  eval {
    local $SIG{PIPE} = sub { die "connection reset (broken pipe)" };
    $self->_writer->send_data( @_ );
  };
  my $e = $@;
  if( $e ) {
    if( $e =~ /^connection reset/
        || $e =~ /^lost connection/ ) {
      $self->_disconnect; # try to cleanup
    }
    die $e;
  }

  if( ! $self->keepalive ) {
    $self->_disconnect;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Lumberjack::Client - a client for the lumberjack protocol

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Net::Lumberjack::Client;

  my $client = Net::Lumberjack::Client->new(
    host => '127.0.0.1',
    port => 5044,
    # for beats server
    keepalive => 0,
    frame_format => 'json',
    ## for a saftpresse (Log::Saftpresse) server
    # keepalive => 1, # or 0
    # frame_format => 'json',
    ## for a lumberjack (v1) server
    # keepalive => 1,
    # frame_format => 'data',
  );

  $client->send_data(
   { message => 'hello world!', lang => 'en' },
   { message => 'Hallo Welt!', lang => 'de' },
  );

=head1 ATTRIBUTES

=head2 host (default: '127.0.0.1')

Host to connect to.

=head2 port (default: 5044)

TCP port to connect to.

=head2 keepalive (default: 0)

If enabled connection will be keept open between send_data() calls.
Otherwise it will be closed and reopened on every call.

Needs to be disabled for logstash-input-beats since it expects only 
one bulk of frames per connection.

=head2 frame_formt (default: 'json')

The following frame formats are supported:

=over

=item 'json', 'v2'

Uses json formatted data frames as defined in lumberjack protocol v2. (type 'J')

=item 'data', 'v1'

Uses lumberjack DATA (type 'D') frames as defined in lumberjack protocol v1.

This format only supports a flat hash structure.

=back

=head2 max_window_size (default: 2048)

Maximum number of frames the clients sends in one bulk.

When hitting this limit the client will split up the stream
into smaller bulks.

=head2 use_ssl (default: 0)

Enable SSL transport encryption.

=head2 ssl_verify (default: 1)

Enable verification of SSL server certificate.

=head2 ssl_ca_file (default: emtpy)

Use a non-default CA file to retrieve list of trusted root CAs.

Otherwise the system wide default will be used.

=head2 ssl_ca_path (default: emtpy)

Use a non-default CA path to retrieve list of trusted root CAs.

Otherwise the system wide default will be used.

=head2 ssl_version (default: empty)

Use a non-default SSL protocol version string.

Otherwise the system wide default will be used.

Check L<IO::Socket::SSL> for string format.

=head2 ssl_hostname (default: emtpy)

Use a hostname other than the hostname give in 'host' for
SSL certificate verification.

This could be used if you use a IP address to connecting to
server that only lists the hostname in its certificate.

=head2 ssl_cert (default: empty)

=head2 ssl_key (default: empty)

If 'ssl_cert' and 'ssl_key' is the client will enable
client side authentication and use the supplied certificate/key.

=head1 METHODS

=head2 send_data( HashRef1, ... )

This method takes a list of HashRefs and sends them to the server.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
