#!/usr/bin/perl
#----------------------------------------------------------------------
=pod

=head1	NAME

    client.pl	-- Example RESTful client.

=head1	SYNOPSIS

    perl client.pl $method $url $arg1 $arg2

    perl client.pl GET    $url $accept_type > results
    perl client.pl PUT    $url $filename $accept_type
    perl client.pl POST   $url $filename $accept_type
    perl client.pl DELETE $url $accept_type

=head1	DESCRIPTION

    This client provides a mechanism whereby RESTful services can be
    invoked.

=head1	PARAMETERS

    $method	-- GET, PUT, POST, DELETE
    $url	-- The RESTful URL that should be invoked.
    $arg1	-- Either $accept_type for GET or $filename for PUT and POST.
    $arg2	-- $accept_type for PUT and POST.
    $accept_type-- The requested response MIME-type.  This must be supported
                   by the remote RESTful service.
		   For example:
                       "text/javascript"	-- JSON
                       "text/html"		-- HTML
                       "text/plain"		-- Text
                       "application/xml"	-- XML
    $filename	-- The name of the file to be uploaded via PUT and POST.
                   If "-", then STDIN will be consumed instead.

=head1	AUTHOR

    John "Frotz" Fa'atuai, frotz@acm.org

=head1	METHODS

=cut

use LWP::UserAgent;
use HTTP::Request;




&main( @ARGV );
exit( 0 );





#----------------------------------------------------------------------
=pod

=head2	main()

USAGE:

    &main( $method, $url, $arg1, $arg2 );
    exit( 0 );

DESCRIPTION:

    This is the main command line processing method.  All work is done
    here.

=cut

sub	main
{
    my( $method )	= shift;
    my( $url )		= shift;
    my( $timeout )	= 30;		## Too short for production
    my( $contents )	= "";
    my( $ua )		= new LWP::UserAgent();
    my( $request )	= new HTTP::Request( $method => $url );

    $ua->timeout( $timeout );
    if  ($method =~ /GET/i)
    {
	my( $accept_type )	= shift || undef;
	$ua->default_header( "Accept"		=> $accept_type )		if  ($accept_type);
    }
    elsif  ($method =~ /PUT|POST/i)
    {
	my( $file )		= shift;
	my( $accept_type )	= shift || undef;
	my( $contents )	= &read( $file );
	$ua->default_header( "Accept"		=> $accept_type )		if  ($accept_type);
	$ua->default_header( "Content-Type"	=> "application/x-www-form-urlencoded" );
	$ua->default_header( "Content-Length"	=> length( $contents ) );
	$request->content( $contents );
    }
    elsif  ($method =~ /DELETE/i)
    {
	my( $accept_type )	= shift || undef;
	$ua->default_header( "Accept"		=> $accept_type )		if  ($accept_type);
    }
    else
    {
	&usage();
    }
    my( $response )	= $ua->request( $request );
    if  ($response->is_success())
    {
	print $response->content();
    }
    else
    {
	print $response->status_line();
    }
}





#----------------------------------------------------------------------
=pod

=head2	read()

USAGE:

    $contents = &read( $file );

DESCRIPTION:

    This method reads the contents of the specified $file or dies.  If
    $file eq "-", then the returned $contents will be everything read
    from <STDIN>.

=cut

sub	read
{
    my( $file )		= shift;
    my( $contents )	= "";
    if  (open( FILE, $file ))
    {
	$contents	= join( "", <FILE> );
	close( FILE );
    }
    elsif ($file eq "-")
    {
	$contents	= join( "", <STDIN> );
    }
    else
    {
	die "read(): Unable to read file [$file]: $!";
    }
    $contents	=~ s/\+/%2B/g;		## @@@ This is insufficient for most needs.
    $contents	=~ s/\ /\+/g;		## @@@ This is insufficient for most needs.
    return( $contents );
}




#----------------------------------------------------------------------
=pod

=head2	usage()

USAGE:

    &usage();

DESCRIPTION:

    This method emits the command line usage and exits.

=cut

sub	usage
{
    print join( "\n",
		"USAGE:",
		"    perl client.pl \$method \$url \$arg",
		"",
		"WHERE:",
		"    \$method is in ('GET', 'PUT', 'POST', 'DELETE')",
		"    \$url is the target RESTful service to invoke.",
		"    \$arg is either:",
		"          \$accept_type for GET or",
		"          \$filename for PUT and POST.",
		"    \$accept_type is the full MIME-type being requested via GET.",
		"    \$filename is "-" for STDIN or the name of the file to PUT / POST.",
		"",
		);
    exit( 1 );
}
