
package Netx::WebRadio::Station::Shoutcast;
use strict;
use warnings;
use Carp;

BEGIN {
    #use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = 0.03;
    #@ISA     = qw (Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    #@EXPORT      = qw ();
    #@EXPORT_OK   = qw ();
    #%EXPORT_TAGS = ();

    use strict;
    use IO::Socket;
    use IO::Poll 0.04 qw(POLLIN POLLOUT POLLERR POLLHUP);
    use Errno qw(EAGAIN EINPROGRESS);

    use Class::MethodMaker
      new_with_init => 'new',
      get_set       =>
      [qw /pollmode host port socket blocking path useragent stationname/];

    %Netx::WebRadio::Station::Shoutcast::pollmodes = (
        START      => undef,
        CONNECT    => POLLOUT,
        SENDHEADER => POLLOUT,
        READHEADER => POLLIN,
        MDSYNC     => POLLIN,
        MDNOSYNC   => POLLIN,
        READMD     => POLLIN
    );
}

=head1 NAME

Netx::WebRadio::Station::Shoutcast - receive one shoutcast-stream

=head1 SYNOPSIS

see Netx::WebRadio
  

=head1 DESCRIPTION

Netx::WebRadio::Station::Shoutcast-objects can be used with Netx::WebRadio to receive a Shoutcast-stream.

=head1 USAGE

You can overload some methods to change the behaviour of the module.

The default implementation does not process the received mp3-data in any way.
Overload some of the methods to process the sound-data.

=head1 METHODS

=head2 host

 Usage     : $station->host( $host  )
 Purpose   : set the hostname of the server
 Returns   : the actual hostname if called without arguments
 Argument  : hostname
 Throws    : nothing
 See Also   : 

=head2 port

 Usage     : $station->port( $port  )
 Purpose   : set the port of the server
 Returns   : the actual port if called without arguments
 Argument  : portnumber
 Throws    : nothing
 See Also   : 

=head2 path

 Usage     : $station->path( $path  )
 Purpose   : set the path of the stream on the server
 Returns   : the actual path if called without arguments
 Argument  : path
 Throws    : nothing
 See Also   : 

=head2 useragent

 Usage     : $station->useragent( 'Winamp...'  )
 Purpose   : set the useragent. the value is sent to the server on connect
 Returns   : the actual useragent if called without arguments
 Argument  : useragent-string
 Throws    : nothing
 See Also   : 


=head2 stationname

 Usage     : $stationname = $station->stationname()
 Purpose   : get the stationname
 Returns   : the stationname
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=head2 receive

 Usage     : $station->receive(  )
 Purpose   :
    Receives next chunk from the station.
    You have to call it everytime the socket is ready for the next operation.
    This is done from Netx::WebRadio in most cases.
 Returns   : 1 for 'ok', other values can be specified in the overloadable method 'disconnected'
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub receive {
    my $self   = shift;
    my $socket = $self->socket;

    if ( $self->get_state eq 'START' ) {
        croak "call connect first\n";
    }

    if ( $self->get_state eq 'CONNECT' ) {
        if ( $socket->connected ) {
            $self->set_state('SENDHEADER');
        }
        else {
            return $self->disconnected();
        }
        return 1;
    }

    if ( $self->get_state eq 'SENDHEADER' ) {
        my $path = $self->path || '/';
        my $header = $self->{_header}
          || "GET $path HTTP/1.0\r\n" . "Host:"
          . $self->host() . "\r\n"
          . "Accept:*/*\r\n"
          . "User-Agent:"
          . $self->useragent() . "\r\n"
          . "Icy-Metadata:1\r\n\r\n";
        my $bytes = $self->icySyswrite( $socket, $header );
        unless ($bytes) {
            return 1 if $! == EAGAIN;
            return $self->disconnected();
        }
        substr( $header, 0, $bytes ) = '';
        unless ($header) {
            $self->set_state('READHEADER');
        }
        $self->{_header} = $header;
        $self->{_header} || delete $self->{_header};
        return 1;
    }

    if ( $self->get_state eq 'READHEADER' ) {
        my $in;
        $self->{_metaLength} = 0;
        my $tLength = $self->icySysread( $socket, $in, 1024 );
        unless ( defined $tLength ) {
            return $self->disconnected();
        }
        my $tempHeader = $self->{_tempHeader} || '';
        $in = $tempHeader . $in;

        if ( $in =~ /\r\n\r\n/ ) {

            # header complete
            $self->{_audio} .= $';    # post-match
            my $header = $`;
            if ( $header =~ /icy-metaint:\s*(\d*)\r\n/i ) {
                $self->{_metaLength} = $1;
            }
            else {
                croak "no length-information in MetaData\n";
            }
            for my $line ( split /\r\n/, $header ) {
                if ( $line =~ /^icy/ ) {
                    my ( $name, $value ) = $line =~ /(icy.*?):(.*)/i;
                    $self->{ '_' . $name } = $value;
                    $self->stationname($value) if $name eq 'icy-name';
                }
            }
            $self->set_state('MDNOSYNC');

            # header complete
            # header ist in $header
        }
        else {
            $self->{_tempHeader} = $in;
        }
        return 1;
    }
    if ( $self->get_state eq 'MDNOSYNC' ) {    # metaData out of sync
        #print "metadaten aus dem takt: " . $self->stationname() . "\n";
        my $in;
        my $restLength = 0;
        my $tLength = $self->icySysread( $socket, $in, $self->{_metaLength} );
        unless ( defined $tLength ) {
            return $self->disconnected();
        }

        $self->{_audio} .= $in;
        if ( $self->{_audio} =~ /Stream(.|\n)*\0/i ) {
            $self->{_audio} =~ /Stream/i;
            my $lastMatch  = $-[0];
            my $stringPre  = $`;
            my $stringPost = $';

            my $lM       = ord( chop($stringPre) ) * 16;
            my $metaData = "Stream" . substr( $stringPost, 0, $lM - 6 );
            my $mreturn  = $self->processMetaData($metaData);
            if ($mreturn) {
                $self->set_state('MDSYNC');
            }

            my $rest = substr( $stringPost, $lM - 6 );
            $self->{_audio} = $stringPre;
            $self->{_audio} .= $rest;
            $restLength = $self->{_metaLength} - length($rest) + 1;
            $self->process_chunk( $self->{_audio} );
        }
        else {
            $self->{_audio} .= $in;
        }
        $self->{_restLength} = $restLength;
        return 1;
    }

    if ( $self->get_state eq 'MDSYNC' ) {
        my $in;
        $self->{_restLength} ||= ( $self->{_metaLength} + 1 );
        my $realLength =
          $self->icySysread( $socket, $in, $self->{_restLength} );
        unless ( defined $realLength ) {
            return $self->disconnected();
        }

        $self->{_restLength} -= $realLength;

        if ( $self->{_restLength} == 0 ) {
            my $l = chop($in);
            $self->process_chunk($in)  if $in;
            $self->set_state('READMD') if ord($l);
            $self->{_newMetaDataLength} = $l;
        }
        else {
            $self->process_chunk($in) if $in;
        }
        return 1;
    }

    if ( $self->get_state eq 'READMD' ) {
        my $in;
        $self->{_newMetaDataLength} ||= 0;
        $self->{_newMetaData}       ||= '';
        my $lengthInBytes =
          ( ord( $self->{_newMetaDataLength} ) * 16 ) -
          length( $self->{_newMetaData} );
        my $realLength = $self->icySysread( $socket, $in, $lengthInBytes );
        unless ( defined $realLength ) {
            return $self->disconnected();
        }

        $self->{_newMetaData} .= $in;

        if ( $realLength < $lengthInBytes ) { return 1 }

        my $metaData = 1;
        $metaData = $self->processMetaData( $self->{_newMetaData} )
          if $self->{_newMetaData};
        $self->{_newMetaData} = '';

        if ($metaData) {
            $self->set_state('MDSYNC');
        }
        else {
            $self->set_state('MDNOSYNC');

        }
        return 1;
    }
}

=head2 connect

 Usage     : $station->connect( $host, $port );
 Purpose   :
    connects the station-object with the radio-station
 Returns   : 1 for 'ok',other values can be specified in the overloadable method 'disconnected'
 Argument  : host, port
 Throws    : nothing
 See Also   : 

=cut

sub connect {
    my ( $self, $host, $port ) = @_;

    $self->host($host) if $host;
    $self->port($port) if $port;

    croak "need more information to connect" unless $self->port && $self->host;

    my $addr = sockaddr_in( $port, inet_aton($host) );
    if ( $self->socket->connect($addr) ) {
        $self->set_state('SENDHEADER');
        return 1;
    }
    else {
        if ( $! == EINPROGRESS ) {
            $self->set_state('CONNECT');
        }
        else {
            $self->disconnected();
            return 0;
        }
    }
    return 1;
}
=pod
The following functions are overloadable:

=head2 init

 Usage     : init is called from new
 Purpose   :
    Initializes some values, create socket
    Always call SUPER::init if you overload this method.
 Returns   : nothing
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub init {
    my $self = shift;

    $self->set_state('START');

    my $socket = IO::Socket::INET->new(
        Proto => 'tcp',
        Type  => SOCK_STREAM
      )
      or die $@;

    $socket->blocking( $self->blocking || 0 );

    $self->socket($socket);
}

=head2 process_chunk

 Usage     : process_chunk is called from receive() for processing audio-data-chunks
 Purpose   :
    overload it
 Returns   : nothing
 Argument  : audio-data
 Throws    : nothing
 See Also   : 

=cut

sub process_chunk {
    my ( $self, $chunk ) = @_;
}

=head2 process_new_title

 Usage     : process_new_title is called everytime the station sends a new song-title
 Purpose   :
    overload it
 Returns   : nothing
 Argument  : new song title
 Throws    : nothing
 See Also   : 

=cut

sub process_new_title {
    my ( $self, $title ) = @_;
    print $title, "\n";
}

=head2 disconnected

 Usage     : is called when there is a write error on a socket
 Purpose   :
    overload it.
    The return value of this method is the value the failed method will return.
    If you can 'fix' the error in this method you normaly return 1, otherwise 0.
    You can also change the behaviour of Netx::WebRadio for a '0' return value.
 Returns   : what you want
 Argument  : nothing
 Throws    : nothing
 See Also   : 

=cut

sub disconnected {
    my $self = shift;
    warn "disconnected " . (caller)[0] . " " . (caller)[2] . "\n";
    return 0;
}

=head1 BUGS

=over 2

=item 1
doesn't work under Win32

=item 2
only works with stations that transmit metdata

=back

=head1 SUPPORT



=head1 AUTHOR

	Nathanael Obermayer
	CPAN ID: nathanael
	natom-pause@smi2le.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).
Netx::WebRadio

=cut

sub set_state {
    my ( $self, $state ) = @_;
    $self->{_state} = $state;
    $self->pollmode( $Netx::WebRadio::Station::Shoutcast::pollmodes{$state} );
}

sub get_state {
    my $self = shift;
    return $self->{_state};
}

sub icySysread {
    my ( $self, $socket, $in, $length ) = @_;
    my $ret = sysread( $socket, $_[2], $length );
    unless ( defined $ret ) {
        if ( $! == EAGAIN ) {
            return 0;
        }
        return undef;
    }
    return $ret;
}

sub processMetaData {
    my ( $self, $text ) = @_;
    my ($title) = $text =~ /StreamTitle='(.*?)'/i;
    return 0 unless $title;
    $self->process_new_title($title);
    return 1;
}

sub icySyswrite {
    my ($self, $socket, $string) = @_;
    return syswrite($socket, $string);
}

1;    #this line is important and will help the module return a true value
__END__

