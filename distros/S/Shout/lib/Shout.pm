package Shout;
use 5.010001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use vars qw($VERSION @ISA);

$VERSION = '2.1.4';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Lib::Foo::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Shout', $VERSION);

shout_init ();

END {
    shout_shutdown ();
}

sub new {
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;
    my $self = $class->raw_new() or return undef; # Call lib function

    ### Set each of the config hash elements by using the keys of the
    ###                config pseudo-hash as the method name
    foreach my $method ( keys %args ) {
        ### Allow keys to be of varying case and preceeded by an optional '-'
        $method =~ s{^-}{};
        $method = lc $method;
        $self->$method( $args{$method} );
    }

    return $self;
}

sub open {
    my $self = shift or croak "open: Method called as function";

    $self->shout_open ? 0 : 1;
}


sub get_connected {
    my $self = shift or croak "open: Method called as function";

    $self->shout_get_connected;
}


sub close {
    my $self = shift or croak "close: Method called as function";

    $self->shout_close ? 0 : 1;
}


sub get_errno {
    my $self = shift or croak "get_errno: Method called as function";

    $self->shout_get_errno or undef;
}


sub get_error {
    my $self = shift or croak "get_error: Method called as function";

    $self->shout_get_error or undef;
}


sub set_metadata ($$) {
    my $self = shift or croak "set_metadata: Method called as function";

    my %param=@_;
    my $md=shout_metadata_new();
    for my $k (keys %param) {
        shout_metadata_add($md,$k,$param{$k});
    }
    $self->shout_set_metadata($md) ? 0 : 1;
}

sub send ($$) {
    my $self = shift        or croak "send_data: Method called as function";
    my $data = shift        or croak "send_data: No data specified";
    my $len = shift || length $data;

    $self->shout_send( $data, $len ) ? 0 : 1;
}

sub sync ($) {
    my $self = shift or croak "sync: Method called as function";

    $self->shout_sync;
}

sub delay ($) {
    my $self = shift or croak "delay: Method called as function";

    $self->shout_delay;
}

sub queuelen ($) {
    my $self = shift or croak "delay: Method called as function";

    $self->shout_queuelen;
}

sub set_audio_info ($$) {
    my $self = shift or croak "set_audio_info: Method called as function";
    my %param=@_;

    for my $k (keys %param) {
        $self->shout_set_audio_info($k, $param{$k}) and return 0;
    }

    1;
}

sub get_audio_info ($$) {
    my $self = shift or croak "get_audio_info: Method called as function";
    my $k = shift or croak "get_audio_info: No parameter supplied";

    return $self->shout_get_audio_info($k);
}

*Shout::disconnect = *Shout::close;
*Shout::sendData   = *Shout::send;
*Shout::error      = *Shout::get_error;
*Shout::sleep      = *Shout::sync;

sub connect ($) {
    my $self = shift or croak "connect: Method called as function";

    $self->format(Shout::SHOUT_FORMAT_MP3());

    return $self->open();
}



sub icy_compat ($$) {
    my $self = shift or croak "icy_compat: Method called as function";
    if (@_) {
        my $compat = shift;

        if ($compat) {
            $self->protocol(Shout::SHOUT_PROTOCOL_ICY()) ? 0 : 1;
        } else {
            $self->protocol(Shout::SHOUT_PROTOCOL_XAUDIOCAST()) ? 0 : 1;
        }
    } else {
        return ($self->protocol == Shout::SHOUT_PROTOCOL_ICY()) ? 1 : 0;
    }
}

sub bitrate ($$) {
    my $self = shift or croak "bitrate: Method called as function";
    if (@_) {
        my $br = shift or croak "bitrate: No parameter specified";

        $self->set_audio_info(Shout::SHOUT_AI_BITRATE(), $br) ? 0 : 1;
    } else {
        return $self->get_audio_info(Shout::SHOUT_AI_BITRATE());
    }
}

sub updateMetadata ($$) {
    my $self = shift or croak "updateMetadata: Method called as function";
    my $metadata = shift or croak "updateMetadata: No metadata specified";

    return $self->set_metadata(song => $metadata) ? 0 : 1;
}

for my $method (qw{
    host
    port
    mount
    password
    user
    dumpfile
    name
    url
    genre
    description
    public
    format
    protocol
    nonblocking
}) {
    my $set_method = "shout_set_$method";
    my $get_method = "shout_get_$method";
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        return $self->$set_method(@_) if @_;
        return $self->$get_method();
    };
}

1;

__END__

=head1 NAME

Shout - Perl glue for libshout MP3 streaming source library

=head1 SYNOPSIS

  use Shout        qw{};

  my $conn = new Shout
        host        => 'localhost',
        port        => 8000,
        mount       => 'testing',
        nonblocking => 0,
        password    => 'pa$$word!',
        user        => 'username',
        dumpfile    => undef,
        name        => 'Wir sind nur Affen',
        url         => 'http://stream.io/'
        genre       => 'Monkey Music',
        description => 'A whole lotta monkey music.',
        format      => SHOUT_FORMAT_MP3,
        protocol    => SHOUT_PROTOCOL_HTTP,
        public      => 0;

  # - or -

  my $conn = Shout->new();

  $conn->host('localhost');
  $conn->port(8000);
  $conn->mount('testing');
  $conn->nonblocking(0);
  $conn->set_password('pa$$word!');
  $conn->set_user('username');
  $conn->dumpfile(undef);
  $conn->name('Test libshout-perl stream');
  $conn->url('http://www.icecast.org/');
  $conn->genre('perl');
  $conn->format(SHOUT_FORMAT_MP3);
  $conn->protocol(SHOUT_PROTOCOL_HTTP);
  $conn->description('Stream with icecast at http://www.icecast.org');
  $conn->public(0);

  ### Set your stream audio parameters for YP if you want
  $conn->set_audio_info(SHOUT_AI_BITRATE => 128, SHOUT_AI_SAMPLERATE => 44100);

  ### Connect to the server
  $conn->open or die "Failed to open: ", $conn->get_error;

  ### Set stream info
  $conn->set_metadata('song' => 'Scott Joplin - Maple Leaf Rag');

  ### Stream some data
  my ( $buffer, $bytes ) = ( '', 0 );
  while( ($bytes = sysread( STDIN, $buffer, 4096 )) > 0 ) {
      $conn->send( $buffer ) && next;
      print STDERR "Error while sending: ", $conn->get_error, "\n";
      last;
  } continue {
      $conn->sync
  }

  ### Now close the connection
  $conn->close;

=head1 EXPORTS

Nothing by default.

=head2 :constants

The following error constants are exported into your package if the
'C<:constants>' tag is given as an argument to the C<use> statement.

        SHOUT_FORMAT_MP3 SHOUT_FORMAT_VORBIS
        SHOUT_PROTOCOL_ICY SHOUT_PROTOCOL_XAUDIOCAST SHOUT_PROTOCOL_HTTP
        SHOUT_AI_BITRATE SHOUT_AI_SAMPLERATE SHOUT_AI_CHANNELS
        SHOUT_AI_QUALITY

=head2 :functions

The following functions are exported into your package if the 'C<:functions>'
tag is given as an argument to the C<use> statement.

        shout_open
        shout_get_connected
        shout_close
        shout_metadata_new
        shout_metadata_free
        shout_metadata_add
        shout_set_metadata
        shout_send_data
        shout_sync
        shout_delay
        shout_set_host
        shout_set_port
        shout_set_mount
        shout_set_nonblocking
        shout_set_password
        shout_set_user
        shout_set_icq
        shout_set_irc
        shout_set_dumpfile
        shout_set_name
        shout_set_url
        shout_set_genre
        shout_set_description
        shout_set_public
        shout_get_host
        shout_get_port
        shout_get_mount
        shout_get_nonblocking
        shout_get_password
        shout_get_user
        shout_get_icq
        shout_get_irc
        shout_get_dumpfile
        shout_get_name
        shout_get_url
        shout_get_genre
        shout_get_description
        shout_get_public
        shout_get_error
        shout_get_errno
        shout_set_format
        shout_get_format
        shout_set_protocol
        shout_get_protocol
        shout_set_audio_info
        shout_get_audio_info
        shout_queuelen

They work almost identically to their libshout C counterparts. See the libshout
documentation for more information about how to use the function interface.

=head2 :all

All of the above symbols can be imported into your namespace by giving the
'C<:all>' tag as an argument to the C<use> statement.

=head1 DESCRIPTION

This module is an object-oriented interface to libshout, an Ogg Vorbis
and MP3 streaming library that allows applications to easily
communicate and broadcast to an Icecast streaming media server. It
handles the socket connections, metadata communication, and data
streaming for the calling application, and lets developers focus on
feature sets instead of implementation details.


=head1 METHODS

=over 4

=item Constructor

None of the keys are mandatory, and may be set after the connection object
is created. This method returns the initialized icecast server
connection object. Returns the undefined value on failure.

Parameters

=over 8

=item host

destination ip address

=item port

destination port

=item mount

stream mountpoint

=item nonblocking

use nonblocking IO

=item password

password to use when connecting

=item user

username to use when connecting

=item dumpfile

dumpfile for the stream

=item name

name of the stream

=item url

url of stream's homepage

=item genre

genre of the stream

=item format

SHOUT_FORMAT_MP3|SHOUT_FORMAT_VORBIS

=item protocol

SHOUT_PROTOCOL_ICY|SHOUT_PROTOCOL_XAUDIOCAST|SHOUT_PROTOCOL_HTTP

=item description

stream description

=item public

list the stream in directory servers?

=back

=item I<open( undef )>

Connect to the target server. Returns undef and sets the object error
message if the open fails; returns a true value if the open
succeeds.

=item I<description( $descriptionString )>

Get/set the description of the stream.

=item I<close( undef )>

Disconnect from the target server. Returns undef and sets the object error
message if the close fails; returns a true value if the close
succeeds.

=item I<dumpfile( $filename )>

Get/set the name of the icecast dumpfile for the stream.  The dumpfile is a
special feature of recent icecast servers. When dumpfile is not
undefined, and the x-audiocast protocol is being used, the icecast
server will save the stream locally to a dumpfile (a dumpfile is just a
raw mp3 stream dump). Using this feature will cause data to be written
to the drive on the icecast server, so use with caution, or you will
fill up your disk!

=item I<get_error( undef )>

Returns a human-readable error message if one has occurred in the
object. Returns the undefined value if no error has occurred.

=item I<get_errno( undef )>

Returns a machine-readable error integer if an error has occurred in the
object. Returns the undefined value if no error has occurred.

=item I<genre( $genreString )>

Get/set the stream's genre.

=item I<host( [$newAddress] )>

Get/set the target host for the connection. Argument can be either an
address or a hostname. It is a fatal error is the argument is a
hostname, and the numeric address cannot be resolved from it.

=item I<mount( $mountPointName )>

Get/set the mountpoint to use when connecting to the server.

=item I<name( $nameString )>

Get/set the name of the stream.

=item I<password( $password )>

Get/set the password to use when connecting to the Icecast server.

=item I<user( $username )>

Get/set the username to use when connecting to the Icecast server.

=item I<port( $portNumber )>

Get/set the port to connect to on the target Icecast server.

=item I<public( $boolean )>

Get/set the connection's public flag. This flag, when set to true, indicates
that the stream may be listed in the public directory servers.

=item I<send( $data[, $length] )>

Send the specified data with the optional length to the Icecast
server. Returns a true value on success, and returns the undefined value
after setting the per-object error message on failure.

=item I<sync( undef )>

Sleep until the connection is ready for more data. This function should be
used only in conjuction with C<send_data()>, in order to send data at the
correct speed to the icecast server.

=item I<delay( undef )>

Tell how much time (in seconds and fraction of seconds) must be
waited until more data can be sent. Use instead of sync() to
allow you to do other things while waiting.

=item I<set_metadata( $newMetadata )>

Update the metadata for the connection. Returns a true value if the update
succeeds, and the undefined value if it fails.

=item I<url( $urlString )>

Get/set the url of the stream's homepage.

=back

=head2 Proxy Methods

=over 4

=item I<AUTOLOAD( @args )>

Provides a proxy for functions and methods which aren't explicitly defined.

=back

=head1 AUTHOR

Jack Moffitt <jack@icecast.org>

=head1 COPYRIGHT

Copyright 2020- Nikolay Shulyakovskiy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
