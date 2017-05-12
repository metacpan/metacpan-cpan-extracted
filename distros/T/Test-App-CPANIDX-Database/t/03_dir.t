use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw[tempdir];
use Test::App::CPANIDX::Database;

my $tmpd = tempdir( DIR => '.', CLEANUP => 1 );

my $loc;
{
   my $tdb = Test::App::CPANIDX::Database->new( dir => $tmpd );
   isa_ok( $tdb, q{Test::App::CPANIDX::Database} );
   diag( $tdb->dbfile );
   ok( -e $tdb->dbfile, 'The database file exists' );
   $loc = $tdb->dbfile;
}

ok( !( -e $loc ), 'The database has gone' );
