use strict;
use warnings;
use File::Temp qw[tempdir];
use Test::More tests => 3;

my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

use Test::App::CPANIDX::Database;

my $loc;
{
   chdir $tmpdir;
   my $tdb = Test::App::CPANIDX::Database->new( unlink => 0 );
   isa_ok( $tdb, q{Test::App::CPANIDX::Database} );
   ok( -e $tdb->dbfile, 'The database file exists' );
   $loc = $tdb->dbfile;
}

ok( -e $loc, 'The database is still there' );

unlink $loc;
