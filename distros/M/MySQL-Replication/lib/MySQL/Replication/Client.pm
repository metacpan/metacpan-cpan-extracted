package MySQL::Replication::Client;

use strict;
use warnings;

use base qw{ Class::Accessor };

use DBI;
use MySQL::Replication::Command;

BEGIN {
  __PACKAGE__->mk_accessors( qw{
    Dbh
    DBName
    RelaySocket
    RelayBuffer
    Host
    Binlog
  });
}

sub new {
  my ( $Class, %Args ) = @_;

  foreach my $Required ( qw{ Dbh DBName RelaySocket Host Binlog } ) {
    if ( not $Args{$Required} ) {
      die "Required parameter '$Required' missing";
    }
  }

  return $Class->SUPER::new( \%Args );
}

sub RequestQueries {
  my ( $Self ) = @_;

  my ( $StartLog, $StartPos ) = $Self->Dbh()->selectrow_array( sprintf( q{
      SELECT Log, Pos
      FROM   %s.SourcePosition
      WHERE  Host   = ?
      AND    Binlog = ?
    }, $Self->DBName() ),
    undef,
    $Self->Host(),
    $Self->Binlog(),
  );

  if ( not defined $StartLog or not defined $StartPos ) {
    die "Error reading source position ($DBI::errstr)" if $DBI::errstr;
    die sprintf( "No source position for source (%s:%s)", $Self->Host(), $Self->Binlog() );
  }

  my $Command = MySQL::Replication::Command->new(
    Command => 'GET',
    Headers => {
      Host     => $Self->Host(),
      Binlog   => $Self->Binlog(),
      StartLog => $StartLog,
      StartPos => $StartPos,
    },
  );

  if ( not $Command ) {
    die "Error creating request ($MySQL::Replication::Command::Errstr)";
  }

  if ( not $Command->SendToSocket( $Self->RelaySocket() ) ) {
    die "Error sending request ($MySQL::Replication::Command::Errstr)";
  }

  return 1;
}

sub GetQueries {
  my ( $Self ) = @_;

  my ( $InsideTransaction, @BufferedQueries );

  while ( 1 ) {
    my $Query = MySQL::Replication::Command->NewFromSocket(
      Socket => $Self->RelaySocket(),
      Buffer => \$Self->{RelayBuffer},
    );

    if ( not $Query ) {
      die "Error reading response ($MySQL::Replication::Command::Errstr)";
    }

    if ( $Query->Command() ne 'QUERY' ) {
      die sprintf( "Invalid command '%s' in response", $Query->Command() );
    }

    foreach my $Required ( qw{ Timestamp Log Pos Length } ) {
      next if $Query->Headers()->{$Required};
      die "Required header '$Required' missing in response";
    }

    if ( $Query->Body() =~ /^\s*ROLLBACK\s*/i ) {
      $InsideTransaction = undef;
      @BufferedQueries   = ();
      next;
    }

    if ( $Query->Body() =~ /^\s*(?:BEGIN|START\s+TRANSACTION)\s*/i ) {
      $InsideTransaction = 1;
      next;
    }

    if ( $Query->Body() =~ /^\s*SET\s*/i ) {
      push @BufferedQueries, $Query;
      next;
    }

    if ( $InsideTransaction ) {
      if ( $Query->Body() =~ /^\s*COMMIT\s*/i ) {
        if ( not @BufferedQueries ) {
          $InsideTransaction = undef;
          next;
        }

        return @BufferedQueries;
      }

      push @BufferedQueries, $Query;
      next;
    }

    if ( $Query->Body() =~ /^\s*COMMIT\s*/i ) {
      return @BufferedQueries if @BufferedQueries;
      next;
    }

    return @BufferedQueries, $Query;
  }
}

sub ExecuteQueries {
  my ( $Self, @Queries ) = @_;

  if ( not @Queries ) {
    die "No queries to execute";
  }

  $Self->Dbh()->do( 'SET SQL_LOG_BIN=0' )
    or die "Error turning off binlogging ($DBI::errstr)";

  $Self->Dbh()->do( 'BEGIN' )
    or die "Error starting transaction ($DBI::errstr)";

  my $Database = '';

  foreach my $Query ( @Queries ) {
    if ( $Query->Headers()->{Database} and $Query->Headers()->{Database} ne $Database ) {
      if ( $Query->Body() !~ /\A\s*(?:CREATE|DROP)\s*(?:DATABASE|SCHEMA)\s+/smi ) {
        $Database = $Query->Headers()->{Database};
        $Self->Dbh()->do( "USE $Database" )
          or die "Error using database '$Database' ($DBI::errstr): " . $Query->Stringify();
      }
    }

    $Self->Dbh()->do( "SET TIMESTAMP=" . $Query->Headers()->{Timestamp} )
      or die "Error setting timestamp ($DBI::errstr)";

    $Self->Dbh()->do( $Query->Body() )
      or die "Error executing query ($DBI::errstr): " . $Query->Stringify();
  }

  $Self->Dbh()->do( sprintf( q{
      UPDATE %s.SourcePosition
      SET    Log    = ?,
             Pos    = ?
      WHERE  Host   = ?
      AND    Binlog = ?
    }, $Self->DBName() ),
    undef,
    $Queries[-1]->Headers()->{Log},
    $Queries[-1]->Headers()->{Pos},
    $Self->Host(),
    $Self->Binlog(),
  ) or die "Error updating source position ($DBI::errstr)";

  $Self->Dbh()->do( 'COMMIT' )
    or die "Error finishing transaction ($DBI::errstr)";

  return 1;
}

1;

__END__

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
