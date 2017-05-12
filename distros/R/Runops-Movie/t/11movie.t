#!perl
use strict;
use warnings;
use Test::More tests => 2;
use IPC::Run qw( run );
use File::Temp qw( tempdir tempfile );

$ENV{PATH} = "blib/script:$ENV{PATH}";

my $moviedir = tempdir( CLEANUP => 1 );
my $mp4 = "$moviedir/movie.mp4";

# Capture a movie log
ok(
  run(
    [ $^X, '-Mblib', 'blib/script/perl-movie',
        '--dir'   => $moviedir,
        '--movie' => $mp4,
        '-e', 'sub bar {} sub foo { bar() } foo() for 1..2' ],
  ),
  'Ran perl-movie'
);

ok( -e $mp4, "Movie $mp4 exists" );
