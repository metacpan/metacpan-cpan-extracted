#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use DBI;
use Test::More qw{ no_plan };
use Getopt::Long;
use MySQL::Replication::Command;
use MySQL::Replication::Client;

InitEnvironment();
Test( ErrorConditions() );
Test( Successful() );

my ( %Options, %RequiredParameters );

sub InitEnvironment {
  my %Options = (
    DBUser => 'test',
    DBPass => 'testpass',
		Schema => 'Replication',
  );

  GetOptions(
    'dbuser=s' => \$Options{DBUser},
    'dbpass=s' => \$Options{DBPass},
		'schema=s' => \$Options{Schema},
  );

  my $Dbh = DBI->connect( "dbi:mysql:$Options{Schema}", $Options{DBUser}, $Options{DBPass} )
    or die "Error connecting to database ($DBI::errstr)";

  %RequiredParameters = (
    Dbh         => $Dbh,
    DBName      => $Options{Schema},
    RelaySocket => \*STDIN,
    Host        => 'localhost',
    Binlog      => 'test',
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
    };
  }

  return @Tests;
}

sub Successful {
  return {
    Name => 'ok',
    Args => \%RequiredParameters,
  };
}

sub Test {
  my ( @Tests ) = @_;

  foreach my $Test ( @Tests ) {
    my $ReplicationClient= eval { MySQL::Replication::Client->new( %{ $Test->{Args} } ) };

    if ( $Test->{Error} ) {
      is( $ReplicationClient, undef, "$Test->{Error} (result)" );
      like( $@, qr/$Test->{Error}/, "$Test->{Error} (error message)" );
    }
    else {
      is( ref $ReplicationClient, 'MySQL::Replication::Client', "$Test->{Name} (result)" );
      is( $@, '', "$Test->{Name} (error message)" );
    }
  }
}
