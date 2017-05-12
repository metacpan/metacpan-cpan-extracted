#!perl -T

use strict;
use warnings;

use Test::More;
use Proc::Hevy;


{
  my ( $stdout, $stderr ) = ( [], [] );
  my $status = Proc::Hevy->exec( command => \&command, stdout => $stdout, stderr => $stderr );
  ok( $status == 0, 'stdxxx: ARRAY reference' );

  {
    my $index = 0;
    for my $text ( qw( foo bar baz ) ) {
      is( $stdout->[$index], $text, "stdout: ARRAY reference ($text)" );
      is( $stderr->[$index], $text, "stderr: ARRAY reference ($text)" );
      $index++;
    }
  }
}

{
  my ( $stdout, $stderr ) = ( [], [] );
  my ( $subout, $suberr ) = ( sub { push @$stdout, shift }, sub { push @$stderr, shift } );
  my $status = Proc::Hevy->exec( command => \&command, stdout => $subout, stderr => $suberr );
  ok( $status == 0, 'stdxxx: CODE reference' );

  {
    my $index = 0;
    for my $text ( qw( foo bar baz ) ) {
      is( $stdout->[$index], $text, "stdout: CODE reference ($text)" );
      is( $stderr->[$index], $text, "stderr: CODE reference ($text)" );
      $index++;
    }
  }
}

# FIXME: add GLOB tests

{
  my ( $stdout, $stderr );
  my $status = Proc::Hevy->exec( command => \&command, stdout => \$stdout, stderr => \$stderr );
  ok( $status == 0, 'stdxxx: GLOB reference' );
  is( $stdout, "foo\nbar\nbaz\n", 'stdout: SCALAR reference' );
  is( $stderr, "foo\nbar\nbaz\n", 'stdout: SCALAR reference' );
}

{
  local $/;
  my ( $stdout, $stderr ) = ( [], [] );
  my $status = Proc::Hevy->exec( command => \&command, stdout => $stdout, stderr => $stderr );
  ok( $status == 0, 'stdxxx: ARRAY reference' );
  is( $stdout->[0], "foo\nbar\nbaz\n", 'stdout: input record seperator' );
  is( $stderr->[0], "foo\nbar\nbaz\n", 'stdout: input record seperator' );
}

done_testing;


sub command { for my $text (qw( foo bar baz )) { print STDOUT "$text\n"; print STDERR "$text\n"; } }
