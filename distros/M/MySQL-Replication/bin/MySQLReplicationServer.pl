#!/usr/bin/perl

use strict;
use warnings;

use base 'Net::Server::Fork';

use DBI;
use Scalar::Util qw{ weaken };
use MySQL::Replication::Server;

use constant {
  LOG_ERR   => 0,
  LOG_DEBUG => 4,
};

my %HANDLERS = (
  QUIT  => \&QUIT,
  PING  => \&PING,
  GET   => \&GET,
  POLL  => \&POLL,
);

__PACKAGE__->new()->run(
  syslog_ident => 'MySQLReplicationServer.pl',
  port         => 2603,
  log_file     => 'Sys::Syslog',
  pid_file     => '/var/run/mysql_replication_server.pid',
);

sub options {
  my ( $Self, $Template ) = @_;

  $Self->{server}{binlog} ||= [];
  $Template->{binlog} = $Self->{server}{binlog};

  $Self->SUPER::options( $Template );
}

sub post_configure {
  my ( $Self ) = @_;

  $Self->SUPER::post_configure();

  foreach my $Required ( qw{ binlog } ) {
    next if @{ $Self->{server}{$Required} };
    die "Required argument '$Required' missing\n";
  }

  foreach my $Binlog ( @{ $Self->{server}{binlog} } ) {
    my ( $Name, $IndexFilename, $ServerId, $BinlogSize ) = split ':', $Binlog;

    if ( not $Name or not $IndexFilename ) {
      die "Invalid format for binlog '$Binlog'\n";
    }

    my $BinlogFilename = _GetLatestBinlog( $IndexFilename );
    my ( $BinlogPath ) = $BinlogFilename =~ m{(.*)\.\d+$};

    $Self->{server}{BinlogPaths}{$Name}    = $BinlogPath;
    $Self->{server}{IndexFilenames}{$Name} = $IndexFilename;
    $Self->{server}{BinlogSize}{$Name}     = $BinlogSize || 2**20*100;

    if ( $ServerId ) {
      $Self->{server}{ServerIds}{$Name} = $ServerId;
    }
  }

  $SIG{__DIE__} = sub {
    $Self->log( LOG_ERR, "Aborting: @_" );
    exit 1;
  };
}

sub process_request {
  my ( $Self ) = @_;

  while ( 1 ) {
    my $Request = MySQL::Replication::Command->NewFromSocket(
      Socket => $Self->{server}{client},
      Buffer => \$Self->{Buffer},
    ); 
  
    if ( not $Request ) {
      die "Error reading request of client ($MySQL::Replication::Command::Errstr)";
    }

    if ( not $HANDLERS{ $Request->Command() } ) {
      die sprintf( "Invalid command '%s' received from client", $Request->Command() );
    }

    next if $HANDLERS{ $Request->Command() }->( $Self, $Request );
    last;
  }
}

sub QUIT {
  my ( $Self ) = @_;

  $Self->log( LOG_ERR, 'Quitting' );
  return;
}

sub PING {
  my ( $Self ) = @_;

  my $Response = MySQL::Replication::Command->new(
    Command => 'PONG',
  );

  if ( not $Response ) {
    die "Error creating PING response ($MySQL::Replication::Command::Errstr)";
  }

  if ( not $Response->SendToSocket( $Self->{server}{client} ) ) {
    die "Error sending PING response ($MySQL::Replication::Command::Errstr)";
  }

  return 1;
}

sub GET {
  my ( $Self, $Request ) = @_;

  foreach my $Required ( qw{ Binlog StartLog StartPos } ) {
    next if $Request->Headers()->{$Required};
    die "Required header '$Required' missing";
  }

  if ( defined $Request->Headers()->{EndLog} and not defined $Request->Headers()->{EndPos} ) {
    die "EndLog header defined but EndPos missing";
  }

  if ( defined $Request->Headers()->{EndPos} and not defined $Request->Headers()->{EndLog} ) {
    die "EndPos header defined but EndLog missing";
  }

  if ( not $Self->{server}{BinlogPaths}{ $Request->Headers()->{Binlog} } ) {
    die sprintf( "Invalid binlog '%s' in request", $Request->Headers()->{Binlog} );
  }

  my $ReplicationServer = MySQL::Replication::Server->new(
    BinlogPath => $Self->{server}{BinlogPaths}{ $Request->Headers()->{Binlog} },
    (
      $Self->{server}{ServerIds}{ $Request->Headers()->{Binlog} }
        ? ( ServerId => $Self->{server}{ServerIds}{ $Request->Headers()->{Binlog} } )
        : (),
    ),
    StartLog   => $Request->Headers()->{StartLog},
    StartPos   => $Request->Headers()->{StartPos},
    (
      $Request->Headers()->{EndLog}
        ? (
            EndLog => $Request->Headers()->{EndLog},
            EndPos => $Request->Headers()->{EndPos},
          )
        : ()
    ),
  ); 

  weaken( my $Weak = $ReplicationServer );

  my $Interrupted;

  my $InterruptListener = AnyEvent->io(
    fh   => $Self->{server}{client},
    poll => 'r',
    cb   => sub {
      $Weak->CondVar()->send();
      $Interrupted++;
    },
  );

  while ( 1 ) {
    my $Query = $ReplicationServer->GetQuery();
    last if not $Query;
    last if $Interrupted;

    if ( $Self->{server}{log_level} == LOG_DEBUG ) {
      $Self->log( LOG_DEBUG, 'Sending: ' . $Query->Stringify() );
    }

    if ( not $Query->SendToSocket( $Self->{server}{client} ) ) {
      die "Error sending query to client ($MySQL::Replication::Command::Errstr)";
    }
  }

  my $RequestComplete = MySQL::Replication::Command->new(
    Command => 'OK',
  );

  if ( not $RequestComplete ) {
    die "Error creating OK response ($MySQL::Replication::Command::Errstr)";
  }

  if ( not $RequestComplete->SendToSocket( $Self->{server}{client} ) ) {
    die "Error sending OK response ($MySQL::Replication::Command::Errstr)";
  }

  return 1;
}

sub POLL {
  my ( $Self, $Request ) = @_;

  if ( not $Request->Headers()->{Binlog} ) {
    die "Required header 'Binlog' missing";
  }

  my $IndexFilename = $Self->{server}{IndexFilenames}{ $Request->Headers()->{Binlog} }
    or die sprintf( "Invalid binlog '%s' in request", $Request->Headers()->{Binlog} );

  my $LatestBinlog = _GetLatestBinlog( $IndexFilename );
  my ( $Log )      = $LatestBinlog =~ m{\.0*(\d+)$};
  
  if ( not $Log ) {
    die sprintf( "Invalid binlog '%s' in index '%s'", $LatestBinlog, $IndexFilename );
  }

  my $Response = MySQL::Replication::Command->new(
    Command => 'STATS',
    Headers => {
      Log        => $Log,
      Pos        => ( -s $LatestBinlog ),
      BinlogSize => $Self->{server}{BinlogSize}{ $Request->Headers()->{Binlog} },
    },
  ) or die "Error creating STATS response ($MySQL::Replication::Command::Errstr)";

  $Response->SendToSocket( $Self->{server}{client} )
    or die "Error sending STATS response ($MySQL::Replication::Command::Errstr)";

  return 1;
}

sub _GetLatestBinlog {
  my ( $IndexFilename ) = @_;

  open my $IndexFh, '<', $IndexFilename
    or die "Error opening index '$IndexFilename' ($!)";

  my @Binlogs = <$IndexFh>;

  if ( not @Binlogs ) {
    die "Index '$IndexFilename' contained no binlogs";
  }

  chomp  $Binlogs[-1];
  return $Binlogs[-1];
}

=pod

=head1 NAME

MySQLReplicationServer.pl - Serves local binlog queries to replication clients 

=head1 SYNOPSIS

  MySQLReplicationServer.pl
    --binlog <name:index>
    --binlog <name:index:serverid>
    --binlog <name:index:serverid:binlogsize>
    --port   <port>

=head1 OPTIONS

MySQLReplicationServer.pl is based on L<Net::Server>, which has a wide range of
configuation options. See L<Net::Server> for more information.

By default, logging is via syslog using the 'daemon' facility (/var/log/messages).

=over

=item binlog (mandatory)

Specifies where binlogs can be found. There are two formats:

=over

=item *

name:index

This specifies the name of the binlog and the path to the binlog index. All
queries will be replicated.

=item *

name:index:serverid

Like above, but only queries with the specified server-id will be replicated.

=item *

name:index:serverid:binlogsize

Like above, but specifies the size of the binlogs (default 100M). This is used
for instrumentation purposes (see L<Instrumentation> for more info)

=back

e.g.:

  --binlog bigdata:/mnt/bitstorage/mysql-bin.index
  --binlog sensitive:/mnt/securestorage/mysql-bin.index:16

Here all queries from the C<bigdata> binlog will be served, but only queries
logged with server-id 16 from the C<sensitive> binlog will be served.

This option can be used multiple times to specify multiple binlogs.

=item port (default 2603)

The port to listen on for replication consumers.

=back

=head1 AUTHOR

Alfie John, C<alfiej@opera.com>

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
