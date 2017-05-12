#!perl -T

use strict;
use warnings;

use Test::More;
use Proc::Hevy;


my @values = ( 2 .. 4 );

ok_exec( 'stdin: simple scalar',   \&command, join( "\n", @values ) );
ok_exec( 'stdin: ARRAY reference', \&command, [ @values ] );
ok_exec( 'stdin: CODE reference',  \&command, do { my @stdin = @values; sub { pop @stdin } } );

# FIXME: add GLOB tests

{
  local $\ = "\0";
  ok_exec( 'stdin: output record seperator', [ \&command, $\ ], \@values );
}

done_testing;


sub ok_exec {
  my ( $name, $command, $stdin ) = @_;

  my $status = Proc::Hevy->exec( command => $command, stdin => $stdin );

  my ( $es, $ec ) = ( ( $status & 0x00ff ), ( $status >> 8 ) );
  ok( $es == 0, $name );
  ok( $ec == 9, $name );
}

sub command {
  my ( $irs ) = @_;

  $/ = $irs
    if defined $irs;

  my $sum = 0;
  while( <> ) {
    chomp;
    $sum += $_;
  }

  exit $sum;
}
