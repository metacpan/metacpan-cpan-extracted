package MySQL::Replication::Command;

use strict;
use warnings;

use version;
our $VERSION = qv( '0.0.1' );

use base qw{ Class::Accessor };

use Errno      qw{ EAGAIN };
use IO::Socket qw{ :crlf  };

our ( $Errstr, $SOCKET_READ_MAX );

BEGIN {
  $SOCKET_READ_MAX = 1024;

  __PACKAGE__->mk_accessors( qw{
    Command
    Headers
    Body
    OutputBuffer
  });
}

sub new {
  my ( $Class, %Args ) = @_;

  $Errstr = undef;

  if ( not $Args{Command} ) {
    $Errstr = "Required parameter 'Command' missing"; 
    return;
  }

  my $Self = $Class->SUPER::new( \%Args );

  if ( not $Args{Headers} ) {
    $Self->Headers( {} );
  }

  if ( $Args{Body} and not $Self->Headers()->{Length} ) {
    $Self->Headers()->{Length} = length $Args{Body};
  }

  return $Self;
}

sub NewFromSocket {
  my ( $Class, %Args ) = @_;

  $Errstr = undef;

  foreach my $Required ( qw{ Socket Buffer } ) {
    next if exists $Args{$Required};

    $Errstr = "Required parameter '$Required' missing";
    return;
  }
  
  #
  # Read the command type and any available headers
  #

  while ( ( ${ $Args{Buffer} } || '' ) !~ /^$CR?$LF/m ) {
    my $Bytes = $Args{Socket}->sysread(
      ${ $Args{Buffer} },
      $SOCKET_READ_MAX,
      length ( ${ $Args{Buffer} } || '' ),
    );

    if ( not defined $Bytes ) {
      if ( $! == EAGAIN ) {
        return if $Args{NonBlocking};
        sleep 1;
        next;
      }

      $Errstr = "Error reading command from socket ($!)";
      return;
    }

    if ( not $Bytes ) {
      $Errstr = 'Lost connection while reading command';
      return;
    }
  }

  #
  # Read the entire body (if any)
  #

  pos( ${ $Args{Buffer} } ) = 0;
  ${ $Args{Buffer} } =~ /\A(\w+)$CR?$LF(.*?)^$CR?$LF/smg;

  my $Command             = $1;
  my $HeadersBuffer       = $2;
  my $CommandHeaderLength = pos( ${ $Args{Buffer} } );

  if ( not $Command ) {
    $Errstr = 'Invalid command format';
    return;
  }

  if ( $HeadersBuffer and $HeadersBuffer =~ /^Length\s*:\s*(\d+)\s*$/m ) {
    my $BodyLength = $1;

    while ( length( ${ $Args{Buffer} } ) - $CommandHeaderLength < $BodyLength + 2 ) {
      my $BytesToRead
        = ( $BodyLength + 2 - length( ${ $Args{Buffer} } ) - $CommandHeaderLength ) > $SOCKET_READ_MAX
          ? $BodyLength + 2 - length( ${ $Args{Buffer} } ) - $CommandHeaderLength
          : $SOCKET_READ_MAX;

      my $Bytes = $Args{Socket}->sysread(
        ${ $Args{Buffer} },
        $BytesToRead,
        length( ${ $Args{Buffer} } ),
      );

      if ( not defined $Bytes ) {
        if ( $! == EAGAIN ) {
          return if $Args{NonBlocking};
          sleep 1;
          next;
        }

        $Errstr = "Error reading body from socket ($!)";
        return;
      }

      if ( not $Bytes ) {
        $Errstr = 'Lost connection while reading body';
        return;
      }
    }
  }

  #
  # Now that we have a full command, strip then extract headers and body (if any)
  #

  ${ $Args{Buffer} } =~ s/\A.*?^$CR?$LF//sm;

  my %Headers;

  if ( $HeadersBuffer ) {
    HEADERS: foreach my $HeaderLine ( split /$CR?$LF/, $HeadersBuffer ) {
      if ( $HeaderLine =~ /^([^:\s]+)\s*:\s*(.+?)\s*$/ ) {
        $Headers{$1} = $2;
      }
      else {
        $Errstr = 'Invalid header format';
        return;
      }
    }
  }

  my $Body;

  if ( $Headers{Length} ) {
    $Body = substr ${ $Args{Buffer} }, 0, $Headers{Length}, '';
    ${$Args{Buffer}} =~ s/\A$CR?$LF//m;
  }

  # 
  # return a new command object
  # 

  return MySQL::Replication::Command->new(
    Command => $Command,
    (
      %Headers
        ? ( Headers => \%Headers )
        : ()
    ),
    (
      $Body
        ? ( Body => $Body )
        : ()
    ),
  );
}

sub SendToSocket{
  my ( $Self, $Socket, %Args ) = @_;

  $Errstr = undef;

  if ( not length( $Self->OutputBuffer() || '' ) ) {
    $Self->OutputBuffer( $Self->Stringify() );
  }

  while ( length( $Self->OutputBuffer() || '' ) ) {
    my $Bytes = $Socket->syswrite( $Self->OutputBuffer() );

    if ( not defined $Bytes ) {
      if ( $! == EAGAIN ) {
        return if $Args{NonBlocking};
        sleep 1;
        next;
      }

      $Errstr = "Error writing command to socket ($!)";
      return;
    }

    substr $Self->{OutputBuffer}, 0, $Bytes, '';

    last if not length( $Self->{OutputBuffer} || '' );
    return if $Args{NonBlocking};
    sleep 1;
  }

  return 1;
}

sub Stringify {
  my ( $Self ) = @_;

  return join( '',
    $Self->Command() . $CRLF,
    (
        map { $_ . ': ' . $Self->Headers()->{$_} . $CRLF }
          sort keys %{ $Self->Headers() || {} }
    ),
    $CRLF,
    (
      $Self->Body()
        ? $Self->Body() . $CRLF
        : ()
    ),
  );
}

1;

__END__

=head1 NAME

MySQL::Replication::Command - Encapsulation of MySQL::Replication IPC

=head1 SYNOPSIS

  my $Request = MySQL::Replication::Command->new(
    Command => 'GET',
    Headers => {
      Host     => $Host,
      Binlog   => $Binlog,
      StartLog => $StartLog,
      StartPos => $StartPos,
    },
  );

  $Request->SendToSocket( $Socket,
    NonBlocking => $NonBlocking,
  );

  my $Response = MySQL::Replication::Command->NewFromSocket(
    Socket      => $Socket,
    Buffer      => $Buffer,
    NonBlocking => $NonBlocking,    
  ); 

  print $Response->Stringify();

=head1 DESCRIPTION

L<MySQL::Replication::Command> contains convenience methods to encapsulate
L<MySQL::Replication> interprocess communication.

=head1 METHODS

=head2 new

  my $Response = MySQL::Replication::Command->new(
    Command => 'QUERY',
    Headers => {
      Timestamp => $Timestamp,
      Database  => $Database,
      Log       => $Log,
      Pos       => $Pos,
      Length    => $Length,
    },
    Body    => $Body,
  );

L<new()> creates a command.

If the return value was C<undef>, inspect
C<$MySQL::Replication::Command::Errstr> for an error message.

=head3 Parameters

=over

=item *

Command (mandatory)

The IPC command type. This parameter is mandatory.

=item *

Headers (optional)

The headers for the command.

=item *

Body (optional)

The body for the command.

The C<Length> header field will be set to the length of C<Body> if it wasn't
provided.

=back

=head2 NewFromSocket

  my $Response = MySQL::Replication::Command->NewFromSocket(
    Socket      => $Socket,
    Buffer      => $Buffer,
    NonBlocking => $NonBlocking,    
  ); 

L<NewFromSocket()> reads a command from the socket.

If the return value was C<undef>, inspect
C<$MySQL::Replication::Command::Errstr> for an error message.

=head3 Parameters

=over

=item *

Socket (mandatory)

The socket to read from.

=item *

Buffer (mandatory)

A reference to the read buffer.

=item *

NonBlocking (optional, default false)

A boolean specifying that reading from the socket is non-blocking.

If C<NonBlocking> is false, then the call will block until the read is
complete.

If C<NonBlocking> is true, then the call will return C<undef> if the read would
have blocked (indicating to try again later).

=back

=head2 SendToSocket

  $Request->SendToSocket( $Socket,
    NonBlocking => $NonBlocking,
  );

L<SendToSocket()> writes the command to the socket.

If the return value was C<undef>, inspect
C<$MySQL::Replication::Command::Errstr> for an error message.

=head3 Parameters

=over 

=item *

$Socket (mandatory)

The socket to write to.

=item *

NonBlocking (optional, default: false)

A boolean specifying that writing to the socket is non-blocking.

If C<NonBlocking> is false, then the call will block until the write is
complete.

If C<NonBlocking> is true, then the call will return C<undef> if the write
would have blocked (indicating to try again later).

=back

=head2 Stringify

  print $Response->Stringify();

L<Stringify()> returns the stringification of the command. This is what gets
written to the socket in L<SendToSocket()>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mysql-replication at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-Replication>. 

=head1 AUTHOR

Alfie John, C<alfiej at opera.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Opera Software Australia Pty. Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the copyright holder nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
