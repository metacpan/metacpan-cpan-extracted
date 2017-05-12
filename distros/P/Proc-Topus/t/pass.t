#!perl

use strict;
use warnings;

use Proc::Topus qw( spawn );
use Test::More;


{
  # basic functionality
  my $handles = spawn({
    workers => {
      pass => {
        count => 2,
      },
    },
  });

  _main( $handles, 'PING', 'PONG' );
}

{
  # loader/main testing
  my ( $req, $res );

  my $handles = spawn({
    main    => sub { my ( $handles ) = @_; ( $req, $res ) = qw( PING PONG ); $handles },
    workers => {
      pass => {
        count  => 2,
        loader => sub { $req = 'PING' },
        main   => sub { $res = 'PONG'; [ @_ ] },
        setsid => 1,
      },
    },
  });

  _main( $handles, $req, $res );
}

{
  # conduit testing
  for my $conduit (qw( socketpair pipe )) {
    # global configuration
    {
      my $handles = spawn({
        conduit => $conduit,
        workers => {
          pass => {
            count => 2,
          },
        },
      });

      _main( $handles, 'PING', 'PONG' );
    }

    # worker configuration
    {
      my $handles = spawn({
        workers => {
          pass => {
            count   => 2,
            conduit => $conduit,
          },
        },
      });

      _main( $handles, 'PING', 'PONG' );
    }
  }
}

{
  # autoflush testing
  for my $autoflush ( 0, 1 ) {
    # global configuration
    {
      my $handles = spawn({
        autoflush => $autoflush,
        workers   => {
          pass => {
            count => 2,
          },
        },
      });

      _main( $handles, 'PING', 'PONG' );
    }

    # worker configuration
    {
      my $handles = spawn({
        workers => {
          pass => {
            count     => 2,
            autoflush => $autoflush,
          },
        },
      });

      _main( $handles, 'PING', 'PONG' );
    }
  }
}


done_testing;


sub _main {
  my ( $handles, $req, $res ) = @_;

  # worker
  if( ref $handles eq 'ARRAY' ) {
    my $bytes = _read( $handles->[0], 5 );
    die "Invalid command: $bytes"
      unless $bytes eq $req;

    _write( $handles->[1], $res, 5 );

    exit 0;
  }

  # master
  _write( $_->{writer}, $req, 5 )
    for @{ $handles->{pass} };

  is( _read( $_->{reader}, 5 ), $res, 'read' )
    for @{ $handles->{pass} };
}

sub _read {
  my ( $fh, $timeout ) = @_;

  vec( my $bits = '', fileno $fh, 1 ) = 1;

  {
    my $rc = select $bits, undef, undef, $timeout;
    die "select: $!"
      if $rc == -1;
    die "select: timed out"
      if $rc == 0;
  }

  {
    my $rc = sysread $fh, my $bytes, 256;
    die "sysread: $!"
      if $rc == -1;
    die "sysread: short read"
      if $rc == 0;

    chomp $bytes;

    $bytes
  }
}

sub _write {
  my ( $fh, $bytes, $timeout ) = @_;

  vec( my $bits = '', fileno $fh, 1 ) = 1;

  {
    my $rc = select undef, $bits, undef, $timeout;
    die "select: $!"
      if $rc == -1;
    die "select: timed out"
      if $rc == 0;
  }

  {
    my $rc = syswrite $fh, $bytes;
    die "syswrite: $!"
      if $rc == -1;
    die "syswrite: short write"
      if $rc != length $bytes;
  }
}
