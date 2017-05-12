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
    or die "Error connecting to databsae ($DBI::errstr)";

  $Dbh->do( 'CREATE DATABASE IF NOT EXISTS replication_test' )
    or die "Error creating test database ($DBI::errstr)";

  $Dbh->do( 'CREATE TABLE IF NOT EXISTS replication_test.execute_queries_test ( value VARCHAR(255) )' )
    or die "Error creating test table ($DBI::errstr)";

  $Dbh->do( 'CREATE DATABASE IF NOT EXISTS replication_test1' )
    or die "Error creating test database ($DBI::errstr)";

  $Dbh->do( 'CREATE TABLE IF NOT EXISTS replication_test1.execute_queries_test ( value VARCHAR(255) )' )
    or die "Error creating test table ($DBI::errstr)";

  $Dbh->do( 'CREATE DATABASE IF NOT EXISTS replication_test2' )
    or die "Error creating test database ($DBI::errstr)";

  $Dbh->do( 'CREATE TABLE IF NOT EXISTS replication_test2.execute_queries_test ( value VARCHAR(255) )' )
    or die "Error creating test table ($DBI::errstr)";
}

sub ErrorConditions {
  my @Tests = (
    {
      Error   => 'No queries to execute',
      Queries => [],
    },
  );

  my @Queries = (
    {
      Error => 'Error turning off binlogging',
      Query => 'SET SQL_LOG_BIN=0',
    },
    {
      Error => 'Error starting transaction',
      Query => 'BEGIN',
    },
    {
      Error => q{Error using database},
      Query => 'USE .*',
    },
    {
      Error  => q{Error setting timestamp},
      Query  => 'SET TIMESTAMP',
    },
    {
      Error => 'Error updating source position',
      Query => "UPDATE $Options{Schema}.SourcePosition",
    },
    {
      Error => 'Error finishing transaction',
      Query => 'COMMIT',
    },
    {
      Error => 'Error executing query',
      Query => 'INSERT INTO execute_queries_test VALUES \( 234 \)',
    }
  );

  foreach my $Query ( @Queries ) {
    push @Tests, {
      Error => $Query->{Error},
      Queries => [
        MySQL::Replication::Command->new(
          Command => 'QUERY',
          Headers => {
            Timestamp => 1299116810,
            Database  => 'replication_test',
            Log       => 33,
            Pos       => 5,
            Length    => 31,
          },
          Body    => 'INSERT INTO execute_queries_test VALUES ( 123 )',
        ),
        MySQL::Replication::Command->new(
          Command => 'QUERY',
          Headers => {
            Timestamp => 1299116810,
            Database  => 'replication_test',
            Log       => 33,
            Pos       => 6,
            Length    => 31,
          },
          Body    => 'INSERT INTO execute_queries_test VALUES ( 234 )',
        ),
        MySQL::Replication::Command->new(
          Command => 'QUERY',
          Headers => {
            Timestamp => 1299116810,
            Database => 'replication_test',
            Log      => 33,
            Pos      => 7,
            Length   => 31,
          },
          Body    => 'INSERT INTO execute_queries_test VALUES ( 345 )',
        ),
      ],
      Pre   => sub {
        no warnings;
        $DBI::db::Olddo = *DBI::db::do{CODE};
        *DBI::db::do    = sub {
          my ( $MyDbh, @Args ) = @_;

          if ( $Args[0] =~ /$Query->{Query}/ ) {
            $MyDbh->DBI::set_err( $DBI::stderr, 'mock error' );
            return;
          }

          $DBI::db::Olddo->( @_ );
        };
      },
      Post  => sub {
        no warnings;
        *DBI::db::do = $DBI::db::Olddo;
      },
    };
  }

  return @Tests;
}

sub Successful {
  my @Queries = (
    {
      Name    => 'No database',
      Queries => [
        {
          Timestamp => 12345678,
          Log       => 33,
          Pos       => 4,
          Body      => 'SET @test:=12345',
        },
        {
          Database  => 'replication_test',
          Timestamp => 12345678,
          Log       => 33,
          Pos       => 5,
          Body      => 'INSERT INTO execute_queries_test VALUES ( @test )',
        },
      ],
      Results => {
        replication_test => [ 12345 ],
      },
    },
    {
      Name    => 'A single query (single database)',
      Queries => [
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 5,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 123 )',
        }
      ],
      Results => {
        replication_test => [ 123 ]
      },
    },
    {
      Name    => 'Multiple queries (single database)',
      Queries => [
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 5,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 123 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 6,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 234 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 7,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 345 )',
        },
      ],
      Results => {
        replication_test => [ 123, 234, 345 ],
      },
    },
    {
      Name    => 'A single query (multiple databases)',
      Queries => [
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 5,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 123 )',
        }
      ],
      Results => {
        replication_test => [ 123 ]
      },
    },
    {
      Name    => 'Multiple queries (multiple databases)',
      Queries => [
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 5,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 123 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 6,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 234 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test',
          Log       => 33,
          Pos       => 7,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 345 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test1',
          Log       => 33,
          Pos       => 8,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 456 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test2',
          Log       => 33,
          Pos       => 9,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 567 )',
        },
        {
          Timestamp => 1299116810,
          Database  => 'replication_test2',
          Log       => 33,
          Pos       => 9,
          Body      => 'INSERT INTO execute_queries_test VALUES ( 678 )',
        },
      ],
      Results => {
        replication_test  => [ 123, 234, 345 ],
        replication_test1 => [ 456           ],
        replication_test2 => [ 567, 678      ],
      },
    },
  );

  my @Tests;

  foreach my $Query ( @Queries ) {
    my @Queries;

    foreach my $Query ( @{ $Query->{Queries} } ) {
      push @Queries, MySQL::Replication::Command->new(
        Command => 'QUERY',
        Headers => {
          Timestamp => 1299116810,
          Database  => ( $Query->{Database} || 'replication_test' ),
          Length    => length( $Query->{Body} ),
          Log       => $Query->{Log},
          Pos       => $Query->{Pos},
        },
        Body    => $Query->{Body},
      ),
    }

    push @Tests, {
      Name    => $Query->{Name},
      Pre     => sub {
        $Dbh->do( 'DELETE FROM replication_test.execute_queries_test' )
          or die "Error initialising test table ($DBI::errstr)";
      },
      Queries => \@Queries,
      Results => $Query->{Results},
    };
  }

  return @Tests;
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    socketpair my $RelayServer, my $RelayClient, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

    my $Consumer = MySQL::Replication::Client->new(
      Dbh         => $Dbh,
      DBName      => $Options{Schema},
      RelaySocket => $RelayServer,
      Host        => 'localhost',
      Binlog      => 'test',
    );

    $Dbh->do( 'DELETE FROM replication_test.execute_queries_test'  );
    $Dbh->do( 'DELETE FROM replication_test1.execute_queries_test' );
    $Dbh->do( 'DELETE FROM replication_test2.execute_queries_test' );

    if ( $Test->{Pre} ) {
      $Test->{Pre}->();
    }

    my $Result = eval { $Consumer->ExecuteQueries( @{ $Test->{Queries} } ) };

    if ( $Test->{Post} ) {
      $Test->{Post}->();
    }

    if ( $Test->{Error} ) {
      is( $Result, undef, "$Test->{Error} (result)" );
      like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
    }
    else {
      is( $Result, 1, "$Test->{Name} (result)" );

      foreach my $Database ( keys %{ $Test->{Results} } ) {
        my $Rows = $Dbh->selectcol_arrayref( "SELECT value FROM $Database.execute_queries_test" )
          or die "Error selecting test records ($DBI::errstr)";

        is_deeply( $Rows, $Test->{Results}{$Database}, "$Test->{Name} (data)" );
      }

      my ( $Log, $Pos ) = $Dbh->selectrow_array( sprintf( q{
					SELECT Log, Pos
					FROM   %s.SourcePosition
					WHERE  Host   = 'localhost'
					AND    Binlog = 'test'
				}, $Options{Schema} ) ) or die "Error reading master status from $Options{Schema}.SourcePosition";

      is( $Log, $Test->{Queries}[-1]->Headers()->{Log}, "$Test->{Name} (Log)" );
      is( $Pos, $Test->{Queries}[-1]->Headers()->{Pos}, "$Test->{Name} (Pos)" );
    }
  }
}
