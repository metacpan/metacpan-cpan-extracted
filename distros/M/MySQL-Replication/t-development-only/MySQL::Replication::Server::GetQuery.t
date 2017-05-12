#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use AnyEvent;
use Test::More qw{ no_plan };
use MySQL::Replication::Server;

require 'MySQL::Replication::Tests.pl';

InitEnvironment();
Test( ErrorConditions() );
Test( Successful() );
Test( MultipleBinlogs() );
Test( MultipleSchemas() );
Test( Transactions() );
Test( Sets() );
Test( AllServerIds() );
Test( FilteredServerIds() );

sub InitEnvironment {
}

sub ErrorConditions {
  my @Tests = (
    {
      Error => 'Error creating binlog read timer',
      Pre   => sub {
        if ( not $AnyEvent::Oldtimer ) {
          my $autoload = AnyEvent->timer(
            after => 1,
            cb    => sub {},
          );
        }

        no warnings;
        $AnyEvent::Oldtimer = *AE::timer{CODE};
        *AE::timer    = sub { return };
      },
      Post  => sub {
        no warnings;
        *AE::timer = $AnyEvent::Oldtimer;
      },
    },
    {
      Error => 'Error creating condition variable',
      Pre   => sub {
        if ( not $AnyEvent::Oldtimer ) {
          my $autoload = AnyEvent->timer(
            after => 1,
            cb    => sub {},
          );
        }

        no warnings;
        $AnyEvent::Oldcondvar = *AnyEvent::Base::condvar{CODE};
        *AnyEvent::Base::condvar = sub { return };
      },
      Post  => sub {
        no warnings;
        *AnyEvent::Base::condvar = $AnyEvent::Oldcondvar;
      },
    },
  );

  return @Tests;
}

sub Successful {
  my @Tests = (
    {
      Name => 'ok',
      Result => [
        MySQL::Replication::Command->new(
          Command => 'QUERY',
          Headers => {
            Timestamp => 1306226200,
            Database  => 'replication_test',
            Log       => 33,
            Pos       => 218,
            Length    => 40,
          },
          Body    => 'DROP DATABASE IF EXISTS replication_test',
        ),
      ],
    },
  );

  return @Tests;
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    my $ReplicationServer;

    $ReplicationServer = MySQL::Replication::Server->new(
      BinlogPath => 'binlogs/test-bin',
      (
        $Test->{ServerId}
          ? ( ServerId  => $Test->{ServerId} )
          : ()
      ),
      StartLog   => ( $Test->{StartLog} || 33 ),
      StartPos   => ( $Test->{StartPos} || 98 ),
      EndLog     => ( $Test->{EndLog} || 33 ),
      EndPos     => ( $Test->{EndPos} || 330 ),
    );

    if ( $Test->{Pre} ) {
      $Test->{Pre}->();
    }

    my @Results;

    foreach my $Query ( @{ $Test->{Result} || [] } ) {
      my $Result = eval { $ReplicationServer->GetQuery() };

      if ( $Test->{Error} ) {
        is( $Result, undef, "$Test->{Error} (result)" );
        like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
        last;
      }

      is( $@, '', sprintf( "$Test->{Name} (error message) [\@%d]", $ReplicationServer->CurrentPos() ) );

      last if not $Result;
      push @Results, $Result;
    }

    if ( $Test->{Post} ) {
      $Test->{Post}->();
    }

    if ( $Test->{Error} ) {
      is_deeply( \@Results, [], "$Test->{Error} (results)" );
      is( $@, '', "$Test->{Error} (error message)" );
    }

    if ( $Test->{Result} ) {
      is_deeply( \@Results, $Test->{Result}, "$Test->{Name} (results)" );
    }
  }
}
