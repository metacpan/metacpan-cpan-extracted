#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use Test::More qw{ no_plan };
use MySQL::Replication::Server;

my ( %RequiredParameters );

InitEnvironment();
Test( ErrorConditions() );
Test( Successful() );

sub InitEnvironment {
  %RequiredParameters = (
    BinlogPath => 'binlogs/test-bin',
    StartLog   => 33,
    StartPos   => 4,
  );
}

sub ErrorConditions {
  my @Tests;

  foreach my $Required ( keys %RequiredParameters ) {
    push @Tests, {
      Error => "Required parameter '$Required' missing",
      Args  => {
        map { $_ => $RequiredParameters{$_} }
          grep { $_ ne $Required }
            keys %RequiredParameters
      },
    },
  }

  push @Tests, (
    {
      Error => 'EndLog specified but EndPos missing',
      Args  => {
        %RequiredParameters,
        EndLog => 33,
      },
    },
    {
      Error => 'EndPos specified but EndLog missing',
      Args  => {
        %RequiredParameters,
        EndPos => 330,
      },
    },
  );

  return @Tests;
}

sub Successful {
  my @Tests = (
    {
      Name => 'ok',
      Args => \%RequiredParameters,
    },
  );

  return @Tests;
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    my $ReplicationServer;
    
    eval {
      $ReplicationServer = MySQL::Replication::Server->new( $Test->{Args} ? %{ $Test->{Args} } : %RequiredParameters );
    };

    if ( $Test->{Error} ) { 
      is( $ReplicationServer, undef, "$Test->{Error}" );
      like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
    }
    else {
      is( ref $ReplicationServer, 'MySQL::Replication::Server', "$Test->{Name}" );
      is( $@, '', "$Test->{Name} (error message)" );

      is( $ReplicationServer->CurrentLog(), $Test->{Args}{StartLog}, "$Test->{Name} (StartLog)" );
      is( $ReplicationServer->CurrentPos(), $Test->{Args}{StartPos}, "$Test->{Name} (StartPos)" );
    }
  }
}
