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

  $Dbh->do( sprintf( q{
			DELETE FROM %s.SourcePosition
			WHERE  Host   = 'localhost'
			AND    Binlog = 'test'
		}, $Options{Schema} ) ) or die "Error deleting source position for localhost:test ($DBI::errstr)";

  $Dbh->do( sprintf( q{
    INSERT INTO %s.SourcePosition ( Host, Binlog, Log, Pos )
    VALUES ( 'localhost', 'test', 33, 4 )
  }, $Options{Schema} ) ) or die "Error initialising source position ($DBI::errstr)";
}

sub ErrorConditions {
  my @Tests = (
    {
      Error => 'Error reading source position \(mock error\)',
      Pre   => sub {
        no warnings;
        $DBI::db::OldSelectrow_array  = *DBI::db::selectrow_array{CODE};
        *DBI::db::selectrow_array = sub {
          $_[0]->DBI::set_err( $DBI::stderr, 'mock error' );
          return;
        };
      },
      Post  => sub {
        no warnings;
        *DBI::db::selectrow_array = $DBI::db::OldSelectrow_array;
      },
    },
    {
      Error => 'No source position for source \(localhost:test\)',
      Pre   => sub {
        $Dbh->do( qq{
          DELETE FROM $Options{Schema}.SourcePosition
          WHERE  Host   = 'localhost'
          AND    Binlog = 'test'
        });
      },
      Post  => sub {
        $Dbh->do( qq{
          INSERT INTO $Options{Schema}.SourcePosition ( Host, Binlog, Log, Pos )
          VALUES ( 'localhost', 'test', 33, 4 )
        });
      },
    },
    {
      Error => 'Error creating request \(mock error\)',
      Pre   => sub {
        no warnings;
        $MySQL::Replication::Command::Oldnew = *MySQL::Replication::Command::new{CODE};
        *MySQL::Replication::Command::new    = sub {
          $MySQL::Replication::Command::Errstr = 'mock error';
          return;
        };
      },
      Post  => sub {
        no warnings;
        *MySQL::Replication::Command::new = $MySQL::Replication::Command::Oldnew;
      },
    },
    {
      Error => 'Error sending request \(mock error\)',
      Pre   => sub {
        no warnings;
        $MySQL::Replication::Command::OldSendToSocket = *MySQL::Replication::Command::SendToSocket{CODE};
        *MySQL::Replication::Command::SendToSocket= sub {
          $MySQL::Replication::Command::Errstr = 'mock error';
          return;
        };
      },
      Post  => sub {
        no warnings;
        *MySQL::Replication::Command::SendToSocket = $MySQL::Replication::Command::OldSendToSocket;
      },
    },
  );

  return @Tests;
}

sub Successful {
  return {
    Name   => 'ok',
  }
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    pipe my $Parent, my $Child;
    socketpair my $RelayServer, my $RelayClient, AF_UNIX, SOCK_STREAM, PF_UNSPEC;

    my $Pid = fork();

    if ( not $Pid ) {
      if ( $Test->{Error} ) {
        syswrite $Child, 'Done';
        sleep;
      }

      my $RelayRequest = MySQL::Replication::Command->NewFromSocket(
        Socket => $RelayClient,
        Buffer => \my $Buffer,
      );

      is_deeply(
        $RelayRequest,
        MySQL::Replication::Command->new(
          Command => 'GET',
          Headers => {
            Host     => 'localhost',
            Binlog   => 'test',
            StartLog => 33,
            StartPos => 4,
          },
        ),
        "$Test->{Name} (request)",
      );

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

    my $Result = eval { $Consumer->RequestQueries() };

    if ( $Test->{Post} ) {
      $Test->{Post}->();
    }

    if ( $Test->{Error} ) {
      is( $Result, undef, "$Test->{Error} (result)" );
      like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
    }
    else {
      ok( $Result, "$Test->{Name} (result)" );
      is( $@, '', "$Test->{Name} (error message)" );
    }

    sysread $Parent, my $Buffer, 100;
    kill 9, $Pid;
  }
}
