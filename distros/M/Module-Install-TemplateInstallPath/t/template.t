#!perl

use Cwd;
use File::Temp;
use File::Spec::Functions qw[ catfile catdir splitpath catpath];
use File::Copy::Recursive qw[ fcopy dircopy ];

my $pdir = getcwd;
my $dist = File::Temp->newdir( DIR => '.', CLEANUP => 1 )
   or die( "unable to create temp directory\n" );

dircopy( catdir( 'blib', 'lib'), catdir( $dist, 'inc' ) );
dircopy( 'inc', catdir( $dist, 'inc' ) );

chdir $dist or die( "unable to cd to $dist\n" );
fcopy ( catfile( $pdir, 't', '00_makefile.pl'), 'Makefile.PL' );

my $err = system( $^X, 'Makefile.PL' );


chdir $pdir;

exit $err;
