#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Pod::Usage;
use Getopt::Long;
use Sys::Syslog qw{ :standard :macros };
use MySQL::Replication::Client;

my ( %Options, $Dbh, $ReplicationClient );

InitEnvironment();
RunReplicationClient();

sub InitEnvironment {
  %Options = (
    SrcPort   => 2603,
    DestHost  => 'localhost',
    DestPort  => 3306,
    DestDB    => 'Replication',
    RelayPort => 2600,
    LogLevel  => 'LOG_ERR',
  );

  GetOptions(
    'srchost=s'   => \$Options{SrcHost},
    'srcport=s'   => \$Options{SrcPort},
    'srcbinlog=s' => \$Options{SrcBinlog},
    'desthost=s'  => \$Options{DestHost},
    'destport=s'  => \$Options{DestPort},
    'destdb=s'    => \$Options{DestDB},
    'destuser=s'  => \$Options{DestUser},
    'destpass=s'  => \$Options{DestPass},
    'relayhost=s' => \$Options{RelayHost},
    'relayport=s' => \$Options{RelayPort},
    'loglevel=s'  => \$Options{LogLevel},
    'pidfile=s'   => \$Options{PidFile},
    'getstats'    => \$Options{GetStats},
  ) or pod2usage( 1 );

  my @RequiredParameters = qw{
    SrcHost
    SrcBinlog
    DestUser
    DestPass
  };

  foreach my $Required ( @RequiredParameters ) {
    next if $Options{$Required};
    print STDERR "Required argument '\L$Required' missing\n\n";
    pod2usage( 1 );
  }

  if ( not $Options{PidFile} ) {
    $Options{PidFile} = "/var/run/mysql_replication_client_$Options{SrcHost}_$Options{SrcBinlog}.pid";
  }

  $0 = "MySQLReplicationClient.pl: --pidfile $Options{PidFile}";

  $Dbh = DBI->connect(
    sprintf( 'dbi:mysql:database=%s;host=%s;port=%s', $Options{DestDB}, $Options{DestHost}, $Options{DestPort} ),
    $Options{DestUser},
    $Options{DestPass}
  ) or die "Error connecting to database ($DBI::errstr)";

  if ( $Options{GetStats} ) {
    GetStats();
    exit;
  }

  if ( -e $Options{PidFile} ) {
    open my $PidFh, '<', $Options{PidFile}
      or die "Error opening pid file $Options{PidFile} ($!)";

    chomp( my $Pid = <$PidFh> );
    close $PidFh;

    die 'Already running' if kill 0, $Pid;
  }

  open my $PidFh, '>', $Options{PidFile}
    or die "Error creating pid file $Options{PidFile} ($!)";

  print $PidFh "$$\n";
  close $PidFh;

  openlog( 'MySQLReplicationClient.pl', 'pid,nofatal' )
    or die 'Error opening syslog';

  eval "setlogmask( LOG_UPTO($Options{LogLevel}) )"
    or die "Error setting log level to $Options{LogLevel}";

  $SIG{__DIE__} = sub {
    syslog( LOG_ERR, "Aborting: @_" );
    exit 1;  
  };

  syslog( LOG_ERR, sprintf( "Starting: Source(%s:%s), Destination(%s:%s:%s), Relay(%s)",
    $Options{SrcHost},
    $Options{SrcBinlog},
    $Options{DestHost},
    $Options{DestPort},
    $Options{DestDB},
    ( $Options{RelayHost} || 'NONE' ),
  ));

  if ( not $Options{RelayHost} ) {
    $Options{RelayHost} = $Options{SrcHost},
    $Options{RelayPort} = $Options{SrcPort},
  }

  my $RelaySocket = IO::Socket::INET->new(
    PeerAddr => $Options{RelayHost},
    PeerPort => $Options{RelayPort},
    Proto    => 'tcp',
  ) or die sprintf( "Error connecting to '%s:%s' ($!)", $Options{RelayHost}, $Options{RelayPort} );

  $ReplicationClient = MySQL::Replication::Client->new(
    Dbh         => $Dbh,
    DBName      => $Options{DestDB},
    RelaySocket => $RelaySocket,
    Host        => $Options{SrcHost},
    Binlog      => $Options{SrcBinlog},
  );
}

sub RunReplicationClient{
  $ReplicationClient->RequestQueries();

  while ( 1 ) {
    my @Queries = $ReplicationClient->GetQueries();

    if ( $Options{LogLevel} eq 'LOG_DEBUG' ) {
      foreach my $Query ( @Queries ) {
        syslog( LOG_DEBUG, $Query->Stringify() );
      }
    }

    $ReplicationClient->ExecuteQueries( @Queries );
  }
}

sub GetStats {
  my $ServerSocket = IO::Socket::INET->new(
    PeerAddr => $Options{SrcHost},
    PeerPort => $Options{SrcPort},
    Proto    => 'tcp',
  ) or die sprintf( "Error connecting to '%s:%s' ($!)", $Options{SrcHost}, $Options{SrcPort} );

  my $Request = MySQL::Replication::Command->new(
    Command => 'POLL',
    Headers => {
      Binlog => $Options{SrcBinlog},
    },
  ) or die "Error creating POLL request ($MySQL::Replication::Command::Errstr)";

  $Request->SendToSocket( $ServerSocket )
    or die "Error sending POLL request ($MySQL::Replication::Command::Errstr)";

  my $Response = MySQL::Replication::Command->NewFromSocket(
    Socket => $ServerSocket,
    Buffer => \my $Buffer,
  ) or die "Error reading response ($MySQL::Replication::Command::Errstr)";

	if ( $Response->Command() ne 'STATS' ) {
		die sprintf( "Invalid response '%s' for POLL", $Response->Command() );
	}

  foreach my $Required ( qw{ Log Pos BinlogSize } ) {
    next if defined $Response->Headers()->{$Required};
    die "Required header '$Required' missing";
  }

  my ( $Log, $Pos ) = $Dbh->selectrow_array( sprintf( q{
      SELECT Log, Pos
      FROM   %s.SourcePosition
      WHERE  Host   = ?
      AND    Binlog = ?
    }, $Options{DestDB} ),
    undef,
    $Options{SrcHost},
    $Options{SrcBinlog},
  );

  if ( not $Log or not $Pos ) {
    die "Error reading local source position ($DBI::errstr)" if $DBI::errstr;
    die 'No local source position';
  }

  use bigint;
  my $BytesBehind
    = ( $Response->Headers()->{BinlogSize} * $Response->Headers()->{Log} + $Response->Headers()->{Pos} )
    - ( $Response->Headers()->{BinlogSize} * $Log + $Pos );

  print join( "\n",
    "LocalLog: $Log",
    "LocalPos: $Pos",
    (
      map { "Remote$_: " . $Response->Headers()->{$_} }
        qw{ Log Pos }
    ),
    "BytesBehind: $BytesBehind",
  ) . "\n";
}

=pod

=head1 NAME

MySQLReplicationClient.pl - Replicates a remote host's binlogs to a local database

=head1 SYNOPSIS

MySQLReplicationClient.pl
  --srchost   <srchost>
  --srcport   <srcport>
  --srcbinlog <srcbinlog>
  --desthost  <desthost>
  --destport  <destport>
  --destdb    <destdb>
  --destuser  <destuser>
  --destpass  <destpass>
  --relayhost <relayhost>
  --relayport <relayport>
  --loglevel  <loglevel>
  --getstats

=head1 DESCRIPTION

This script will:

=over

=item *

Connect to the replication server running on the source host (or a relay)

=item *

Request binlog queries starting from the local binlog position

=item *

Read query responses and execute them on the local database

=item *

Update the local binlog position after each query has been executed

=back

A running instance will replicate from a single source i.e.:

  +----------------+       +-----------------+
  | local database |<------| source database |
  +----------------+       +-----------------+

To replicate from multiple sources, simply run it multiple times i.e.:

  +----------------+       +------------------+
  |                |<------| source database1 |
  |                |       +------------------+
  |                |
  |                |       +------------------+
  | local database |<------| source database2 |
  |                |       +------------------+
  |                |       
  |                |       +------------------+
  |                |<------| source database3 |
  +----------------+       +------------------+

=head2 First Time Setup

=head3 Stop MySQL's Built-In Replication

MySQL's built-in replication must be stopped between the source host and the
local database before continuing. Otherwise MySQL's built-in replication and
this script will execute the same queries leading to incorrect data.

On the slave host:

  SLAVE STOP

=head3 Create the Replication Schema

The replication schema is where internal replication data will be stored.
Before running the replication client for the first time, this schema will need
to be created on the local database:

  SET SQL_LOG_BIN=0;

  CREATE DATABASE IF NOT EXISTS Replication;
  USE Replication;

  CREATE TABLE IF NOT EXISTS SourcePosition (
    Host    VARCHAR(255) NOT NULL,
    Binlog  VARCHAR(255) NOT NULL,
    Log     MEDIUMINT    NOT NULL,
    Pos     INT          NOT NULL,
    PRIMARY KEY ( Host, Binlog )
  ) ENGINE=InnoDB;

By default the 'Replication' schema name is used.

=head3 Grant Permissions

Since all queries from the replication server will be executed on the local
database, appropriate permissions must be granted to the provided credentials.

Note that the C<SUPER> privilege will also need to be granted since it will be
modifying the system variable C<SQL_LOG_BIN>.

=head3 Setting the Local Binlog Position

Before running the replication client for the first time, it will need to know
where to start replicating from:

  SET SQL_LOG_BIN=0;

  INSERT INTO Replication.SourcePosition VALUES
  ( srchost, srcbinlog, startlog, startpos );

B<WARNING: Is is essential that turning off binlogging here is done before the
insert. Otherwise all replication clients of this host will see the insert and
update their own internal binlog positions.>

The value of startlog and startpos will depend on how the local MySQL database
was created.

To pick up from where MySQL's built-in replication stopped, use the values from
C<SHOW SLAVE STATUS>:

  > SHOW SLAVE STATUS\G
  ...	
  Relay_Master_Log_File: binlog-filename.<startlog>
  Exec_Master_Log_Pos: <startpos>

To start from a known query within a binlog on the source host:

  $ mysqlbinlog binlog-filename.<startlog> | less
  ...
  # at <startpos>
	QueryText

=head3 Turn off MySQL's Built-In Replication

To stop MySQL's built-in replication from resuming on a restart, on the slave
host:

  RESET SLAVE
  CHANGE MASTER TO MASTER_HOST=''

=head2 Confirm it's working

To confirm that replication is working:

=over

=item

You can query the replication position directly:

  SELECT * FROM Replication.SourcePosition

=item

Use the --getstats option along with all the required options:

  ./MySQLReplicationClient ... --getstats

=back

=head1 OPTIONS

=over

=item srchost (mandatory)

The source host of the binlogs to replicate from.

=item srcport (default: 2603)

The port of the replication server running on the source host.

=item srcbinlog (mandatory)

The name of the binlog we want to replicate.

=item desthost (default: localhost)

The host of the local MySQL server to replicate into.

This value is usually 'localhost' however MySQL can be configured to bind to
a specific IP address instead of all interfaces.

=item destport (default: 3306)

The port of the local MySQL server.

=item destdb (default: Replication)

The schema used for internal replication data such as the local binlog positions.

=item destuser (mandatory)

=item destpass (mandatory)

Credentials to the local MySQL server.

=item relayhost

If not specified, connect directly to the source host to replicate from.

If specified, connect instead to a replication relay host to replicate from.

A replication relay acts as a proxy cache for multiple replication clients.

=item relayport (default: 2600)

The port of the replication relay server.

=item loglevel (default: LOG_ERR)

Logging is via syslog, using the 'daemon' facility (by default to /var/log/messages).

The syslog log level. Possible values are:

=over

=item *

LOG_CRIT

Since no log messages are at LOG_CRIT or above, this effectively turns off
logging.

=item *

LOG_ERR

Log all errors.

=item *

LOG_DEBUG

Log all errors and query responses.

=back

=item getstats

Displays statistics on how replication is proceeding.

=back

=head1 BUGS

=over

=item *

Currently, row-based replication and LOAD DATA INFILE and related queries
aren't supported. If encountered, replication will stop.

=item *

Since all queries coming over the wire will be in plain text, it is important
that traffic be routed through a secure tunnel.

=item *

The relay isn't complete yet (but it's coming soon)

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
