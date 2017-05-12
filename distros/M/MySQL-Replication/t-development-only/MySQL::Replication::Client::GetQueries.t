#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use DBI;
use Test::More qw{ no_plan };
use Getopt::Long;
use IO::Socket::INET;
use MySQL::Replication::Command;
use MySQL::Replication::Client;

my ( %Options, $Dbh );

InitEnvironment();
Test( ErrorConditions() );
Test( Successful() );

sub InitEnvironment {
  %Options = (
    DBUser => 'test',
    DBPass => 'testpass',
		Schema => 'Replication',
  );

  GetOptions(
    'dbuser=s' => \$Options{DBUser},
    'dbpass=s' => \$Options{DBPass},
		'schema=s' => \$Options{Schema},
  );

  $Dbh = DBI->connect( "dbi:mysql:$Options{Schema}", $Options{DBUser}, $Options{DBPass} )
    or die "Error connecting to database ($DBI::errstr)";
}

sub ErrorConditions {
  my @Tests = (
    {
      Error         => 'Error reading response \(mock error\)',
      RelayResponse => [
        MySQL::Replication::Command->new(
          Command => 'MOCK',
        ),
      ],
      Pre           => sub {
        no warnings;
        $MySQL::Replication::Command::OldNewFromSocket = *MySQL::Replication::Command::NewFromSocket{CODE};
        *MySQL::Replication::Command::NewFromSocket    = sub {
          $MySQL::Replication::Command::Errstr = 'mock error';
          return;
        };
      },
      Post          => sub {
        no warnings;
        *MySQL::Replication::Command::NewFromSocket = $MySQL::Replication::Command::OldNewFromSocket;
      },
    },
  );

  push @Tests, (
    {
      Error         => "Invalid command 'MOCK' in response",
      RelayResponse => [
        MySQL::Replication::Command->new(
          Command => 'MOCK',
        ),
      ],
    },
  );

  my %RequiredHeaders = (
    Timestamp => time,
    Log       => 33,
    Pos       => 4,
    Length    => 8,
  );

  foreach my $Required ( keys %RequiredHeaders ) {
    push @Tests, {
      Error         => "Required header '$Required' missing in response",
      RelayResponse => [
        MySQL::Replication::Command->new(
          Command => 'QUERY',
          Headers => {
            map { $_ => $RequiredHeaders{$_} }
              grep { $_ ne $Required }
                keys %RequiredHeaders
          },
          ( $Required eq 'Length' ? () : ( Body => 'SELECT 1' ) ),
        ),
      ],
    };
  }

  return @Tests;
}

sub Successful {
  my @QuerySets = (
    {
      Name    => 'No transaction',
      Queries => [
        'INSERT INTO test VALUES ( 1 )',
      ],
    },
    {
      Name    => 'No transaction SET',
      Queries => [
        'SET @@test=1',
        'INSERT INTO test VALUES ( 1 )',
      ],
    },
    {
      Name    => 'COMMIT without transaction',
      Queries => [
        'SET @@test=1',
        'COMMIT',
      ],
    },
    {
      Name    => 'Empty transaction with ROLLBACK',
      Queries => [
        'ROLLBACK',
        'SELECT 1',
      ],
    },
    {
      Name    => 'Non-empty transaction with ROLLBACK',
      Queries => [
        'BEGIN',
        'INSERT INTO test VALUES ( 1 )',
        'ROLLBACK',
        'SELECT 1',
      ],
    },
    {
      Name    => 'SET transaction with ROLLBACK',
      Queries => [
        'BEGIN',
        'SET @@test=1',
        'ROLLBACK',
        'SELECT 1',
      ],
    },
    {
      Name    => 'Non-empty with SET transaction with ROLLBACK',
      Queries => [
        'BEGIN',
        'INSERT INTO test VALUES ( 1 )',
        'SET @@test=1',
        'ROLLBACK',
        'SELECT 1',
      ],
    },
    {
      Name    => 'Empty transaction (BEGIN)',
      Queries => [
        'BEGIN',
        'COMMIT',
        'SELECT 1',
      ],
    },
    {
      Name    => 'Non-empty transaction (BEGIN)',
      Queries => [
        'BEGIN',
        'INSERT INTO test VALUES ( 1 )',
        'INSERT INTO test VALUES ( 2 )',
        'INSERT INTO test VALUES ( 3 )',
        'COMMIT',
      ],
    },
    {
      Name    => 'Non-empty with SET transaction (BEGIN)',
      Queries => [
        'BEGIN',
        'INSERT INTO test VALUES ( 1 )',
        'SET @@test=1',
        'INSERT INTO test VALUES ( 2 )',
        'SET @@test=2',
        'INSERT INTO test VALUES ( 3 )',
        'COMMIT',
      ],
    },
    {
      Name    => 'Empty transaction (START TRANSACTION)',
      Queries => [
        'START TRANSACTION',
        'COMMIT',
        'SELECT 1',
      ],
    },
    {
      Name    => 'Non-empty transaction (START TRANSACTION)',
      Queries => [
        'START TRANSACTION',
        'INSERT INTO test VALUES ( 1 )',
        'INSERT INTO test VALUES ( 2 )',
        'INSERT INTO test VALUES ( 3 )',
        'COMMIT',
      ],
    },
    {
      Name    => 'Non-empty with SET transaction (START TRANSACTION)',
      Queries => [
        'START TRANSACTION',
        'INSERT INTO test VALUES ( 1 )',
        'SET @@test=1',
        'INSERT INTO test VALUES ( 2 )',
        'SET @@test=2',
        'INSERT INTO test VALUES ( 3 )',
        'COMMIT',
      ],
    },
  );

  my @Tests;

  foreach my $QuerySet ( @QuerySets ) {
    my @Responses;
    my @Results;

    for ( my $i = 0; $i < @{ $QuerySet->{Queries} }; $i++ ) {
      push @Responses, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          Database  => $Options{Schema},
          Timestamp => 12345,
          Log       => 33,
          Pos       => 33 + $i,
          Length    => length( $QuerySet->{Queries}[$i] ),
        },
        Body    => $QuerySet->{Queries}[$i],
      );

      if ( $QuerySet->{Queries}[$i] =~ /ROLLBACK/ ) {
        @Results = ();
        next;
      }

      if ( $QuerySet->{Queries}[$i] =~ /BEGIN|START TRANSACTION|COMMIT/ ) {
        next;
      }

      push @Results, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          Database => $Options{Schema},
          Timestamp => 12345,
          Log       => 33,
          Pos       => 33 + $i,
          Length    => length( $QuerySet->{Queries}[$i] ),
        },
        Body    => $QuerySet->{Queries}[$i],
      );
    }

    push @Tests, (
      {
        Name          => $QuerySet->{Name},
        RelayResponse => \@Responses,
        Result        => \@Results,
      }
    );
  }

  return @Tests;
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    pipe my $Parent, my $Child;
    socketpair my $RelayServer, my $RelayClient, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

    my $Pid = fork();

    if ( not $Pid ) {
      foreach my $Response ( @{ $Test->{RelayResponse} } ) {
        $Response->SendToSocket( $RelayClient );
      }

      syswrite $Child, 'Done';
      sleep;
    }

    my $Consumer = MySQL::Replication::Client->new(
      Dbh         => $Dbh,
      DBName      => $Options{Schema},
      RelaySocket => $RelayServer,
      Host        => 'localhost',
      Binlog      => 'test',
    );

    if ( $Test->{Pre} ) {
      $Test->{Pre}->();
    }

    my @Queries = eval { $Consumer->GetQueries() };

    if ( $Test->{Post} ) {
      $Test->{Post}->();
    }

    if ( $Test->{Error} ) {
      is_deeply( \@Queries, [], "$Test->{Error} (result)" );
      like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
    }
    else {
      is_deeply( \@Queries, $Test->{Result}, "$Test->{Name} (queries)" );
      is( $@, '', "$Test->{Name} (error message)" );
    }

    sysread $Parent, my $Buffer, 100;
    kill 9, $Pid;
  }
}
