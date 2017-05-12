# -*- Mode: Perl; -*-
#----------------------------------------------------------------------
package main;

use blib;
use Test::More;
eval "use Test::Pod 1.00";
if ( $@ )
{
    &plan( skip_all => "Test::Pod 1.00 required for testing POD" );
}
else
{
    &main( "../lib", "lib" );
}
exit( 0 );




#----------------------------------------------------------------------
sub	main
{
    my( @dirs )		= @_;
    my( @files )	= ();
    foreach my $dir (@dirs)
    {
	next		unless( -d $dir );

	push( @files, &find_files( $dir ) );
    }
    &plan( tests => $#files+1 );
    foreach my $file (@files)
    {
	&pod_file_ok( $file, $file );
    }
}




#----------------------------------------------------------------------
sub	find_files
{
    my( $dir )		= shift;
    my( @files )	= ();

    opendir( DIRP, $dir );
    my( @entries )	= sort( readdir( DIRP ) );
    closedir( DIRP );

    foreach my $entry (@entries)
    {
	if  ($entry eq "." ||
	     $entry eq "..")
	{
	}
	elsif (-d "$dir/$entry")
	{
	    push( @files, &find_files( "$dir/$entry" ) );
	}
	elsif (-f "$dir/$entry")
	{
	    push( @files, "$dir/$entry" );
	}
    }
    return( @files );
}
