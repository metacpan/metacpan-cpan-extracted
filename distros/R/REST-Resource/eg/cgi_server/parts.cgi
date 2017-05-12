#!/usr/bin/perl
#----------------------------------------------------------------------
=pod

=head1	NAME

    /parts.cgi		-- Sample REST::Resource CGI

=head1	SYNOPSIS

    http://server/pathto/parts.cgi	-- Get the parts list

=head1	DESCRIPTION

    This script demonstrates how to derive from REST::Resource and add
    specialized HTTP method handlers.

=head1	AUTHOR

    frotz@acm.org

=cut





#----------------------------------------------------------------------
=pod

=head1	METHODS - main::

=cut

package	main;


use lib "../lib";
use Data::Dumper;
use CGI::Carp;

#### use Restful::Parts::Resource;		## This is defined above.

&main();
exit( 0 );





#----------------------------------------------------------------------
=pod

=head2	main()

USAGE:

    &main();
    exit( 0 );

DESCRIPTION:

    This is the top-level method for this CGI script.

=cut
sub	main
{
    my( $restful )	= new Restful::Parts::Resource();
    $restful->handle_request();
}





#----------------------------------------------------------------------
=pod

=head1	METHODS - Restful::Parts::Resource

=cut

package	Restful::Parts::Resource;

use blib;
use Data::Dumper;
use base qw( REST::Resource );
use HTTP::Status;

our( $VERSION )	= '0.5.2.4';	## MODULE-VERSION-NUMBER



#----------------------------------------------------------------------
=pod

=head2	new()

USAGE:

    my( $restful )	= new Restful::Parts::Resource();
    $restful->handle_request();
		## OR
    $restful->run();

DESCRIPTION:

    This constructor registers all handlers for this RESTful resource.

=cut

sub	new
{
    my( $proto )	= shift;
    my( $class )	= ref( $proto );
    $class		= $proto		unless( $class );
    my( $this )		= $class->SUPER::new();
    $this->method( "GET",    \&Restful::Parts::Resource::dispatcher, "Returns a structured list of parts." );
    $this->method( "PUT",    \&Restful::Parts::Resource::dispatcher, "Create an existing part." );
    $this->method( "POST",   \&Restful::Parts::Resource::dispatcher, "Modify an existing part." );
    $this->method( "DELETE", \&Restful::Parts::Resource::dispatcher, "Remove an existing part." );
    $this->method( "HEAD",   \&Restful::Parts::Resource::dispatcher, "Discover this resource's API." );
    $this->method( "api",    \&Restful::Parts::Resource::dispatcher, "Discover this resource's API." );

    $this->format( "text/html",	 \&Restful::Parts::Resource::format_html, "Returns HTML UI.  Request via 'Accept: text/html' or '?format=html'" );

    unless  (-d "./.data/")
    {
	mkdir( "./.data", 0755 );
    }
    return( $this );
}





#----------------------------------------------------------------------
=pod

=head2	dispatcher()

USAGE:

    $this->method( "GET",    \&Restful::Parts::Resource::dispatcher, "Returns a structured list of parts." );
    $this->method( "PUT",    \&Restful::Parts::Resource::dispatcher, "Create an existing part." );
    $this->method( "POST",   \&Restful::Parts::Resource::dispatcher, "Modify an existing part." );
    $this->method( "DELETE", \&Restful::Parts::Resource::dispatcher, "Remove an existing part." );
    $this->method( "HEAD",   \&Restful::Parts::Resource::dispatcher, "Discover this resource's API." );
    $this->method( "api",    \&Restful::Parts::Resource::dispatcher, "Discover this resource's API." );

DESCRIPTION:

    This method interrogates the request and routes to the appropriate
    derived class method.

=cut

sub	dispatcher
{
    my( $this )		= shift;
    my( $cgi )		= shift;
    my( $request )	= $this->_interrogate_request( $cgi );

    if  ($request->{create})
    {
	return( $this->create_part( $request ) );
    }
    elsif  ($request->{modify})
    {
	return( $this->modify_part( $request ) );
    }
    elsif  ($request->{delete})
    {
	return( $this->delete_part( $request ) );
    }
    elsif  ($request->{api})
    {
	return( $this->api( $cgi ) );
    }
    else
    {
	return( $this->parts_list( $request ) );
    }
}



#----------------------------------------------------------------------
=pod

=head2	parts_list()	- GET

USAGE:

    my( $status, \%data ) = $restful->parts_list( $request_interface_instance );

DESCRIPTION:

    This method retrieves the number of parts currently known by this
    RESTful resource.

PATH INFO SEMANTICS:

    None	-- Return the list of all parts
	200	-- $data->{count} contains the number of known parts.
    		   $data->{parts} is a hashref containing all known parts.

    /part/$part	-- Return JUST the information for part => $part.
	200	-- $data->{part} is the requested part.
		   $data->{desc} is the requested part description.
        404	-- Unable to read description for part => $part.

=cut

sub	parts_list
{
    my( $this )		= shift;
    my( $data )		= shift;
    my( $status );

    if (-f "./.data/$data->{part}")
    {
	eval
	{
	    $data->{desc}	= $this->_read( "./.data/$data->{part}" );
	};
	if  ($@)
	{
	    $status		= RC_NOT_FOUND;		## 404
	    $data->{exception}	= $@;
	}
    }
    else
    {
	$status		= RC_OK;
	$data->{parts}	= {};
	$parts->{count}	= 0;

	opendir( DIRP, "./.data/" );
	my( @entries )	= sort( readdir( DIRP ) );
	closedir( DIRP );
	foreach my $entry (@entries)
	{
	    if  (-f "./.data/$entry")
	    {
		$data->{parts}->{$entry}	= $this->_read( "./.data/$entry" );
		$data->{count}++;
	    }
	}
    }
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	create_part()	- PUT

USAGE:

    my( $status, $data ) = $restful->create_part( $request_interface_instance );

DESCRIPTION:

    This method creates a new part that will be known by this RESTful
    resource.

STATUS CODES:

    201		-- Part created successfully.
    302		-- Unable to create part.
    412		-- Required data not provided.

=cut

sub	create_part
{
    my( $this )		= shift;
    my( $data )		= shift;
    my( $status );
    if  (defined( $data->{part} ))
    {
	if  (defined( $data->{desc} ))
	{
	    eval
	    {
		$this->_write( "./.data/$data->{part}", $data->{desc} );
		$status		= RC_CREATED;			## 201
	    };
	    if  ($@)
	    {
		$status		= RC_NOT_MODIFIED;		## 302
	    }
	}
	else
	{
	    $status		= RC_PRECONDITION_FAILED;	## 412
	    $data->{desc}	= "-Unspecified-";
	}
    }
    else
    {
	$status		= RC_PRECONDITION_FAILED;		## 412
	$data->{create}	= "-Unspecified-";
	$data->{desc}	= $desc;
    }
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	modify_part()	- PUT

USAGE:

    my( $status, $data ) = $restful->modify_part( $request_interface_instance );

DESCRIPTION:

    This method modifies an existing part known by this RESTful
    resource.

STATUS CODES:

    200		-- Part modified successfully.
    304		-- Unable to modify part.
    404		-- No part specified.

=cut

sub	modify_part
{
    my( $this )		= shift;
    my( $data )		= shift;
    my( $status );

    if  (-f "./.data/$data->{part}")
    {
	if  ($data->{desc})
	{
	    eval
	    {
		$this->_write( "./.data/$data->{part}", $data->{desc} );
		$status		= RC_OK;	## 200
	    };
	    if  ($@)
	    {
		$status	= RC_NOT_MODIFIED;	## 304
		$data	= $@;
	    }
	}
	else
	{
	    $status	= RC_NOT_MODIFIED;	## 304
	    $data	= "No description specified.";
	}
    }
    else
    {
	$status		= RC_NOT_FOUND;		## 404
	$data		= "Non-existent part specified.";
    }
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	delete_part()	- DELETE

USAGE:

    my( $status, $data ) = $restful->delete_part( $request_interface_instance );

DESCRIPTION:

    This method removes an existing part known by this RESTful
    resource.

STATUS CODES:

    200		-- Part removed successfully.
    404		-- Unable to remove part.

=cut

sub	delete_part
{
    my( $this )		= shift;
    my( $data )		= shift;
    my( $status );

    if  (-f "./.data/$data->{part}")
    {
	eval
	{
	    unlink( "./.data/$data->{part}" );
	    $status	  	= RC_OK;	## 200
	};
	if  ($@)
	{
	    $status	= RC_NOT_FOUND;		## 404
	}
    }
    else
    {
	$status		= RC_NOT_FOUND;		## 404
    }
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	format_html()

USAGE:

    print $this->format_html( $request_interface_instance, $status, $data );

DESCRIPTION:

    Format $data such that if $data->{parts} exists, then we want a sorted table of parts.
    Otherwise, we assume we are just dealing with a specific part.

=cut

sub	format_html
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;
    my( $content )	= join( "",
				$req->header( -status => $status,
					      -content_type => "text/html" ),
				);
    if  ($data->{delete} || $data->{modify} || $data->{create})
    {
	my( $operation )	= "DELETE"	if ($data->{delete});
	$operation		= "UPDATE"	if ($data->{modify});
	$operation		= "CREATE"	if ($data->{create});

	my( $timestamp )	= time();
	$content	.= join( "\n",
				 "<html>",
				 "<head>",
				 " <meta http-equiv='refresh' content='02; url=$ENV{SCRIPT_NAME}/request/${timestamp}.$$;'/>",
				 "</head>",
				 "<body>",
				 "<div> NAVIGATION:",
				 "  <a href='$ENV{SCRIPT_NAME}/request/${timestamp}.$$'>Parts List</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}/api'>API</a>",
				 "</div>",
				 "<b>$operation OPERATION " . ($status >= 200 && $status <= 299 ? "SUCCESSFUL</b>" : "FAILED: $!</b>" ),
####				 "<pre>" . Dumper( $data ) . "</pre>",
				 );
    }
    elsif  (exists( $data->{parts} ))
    {
	my( $url )	= "http://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";
	$content	.= join( "\n",
				 "<html>",
				 "<body>",
				 "<div> NAVIGATION:",
				 "  <a href='$ENV{SCRIPT_NAME}'>All Parts</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}?format=xml'>XML</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}?format=json'>JSON</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}?format=text'>text</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}/api'>API</a>",
				 "</div>",
				 "<table border='1' cellpadding='5' cellspacing='1'>",
				 "<tr>",
				 "<th>Part #</th>",
				 "<th>Description</th>",
				 "<th>Formats</th>",
				 "</tr>",
				 );
	foreach $part (sort( keys( %{ $data->{parts} } ) ))
	{
	    my( $desc )	= $data->{parts}->{$part};
	    $desc	=~ s/&/&amp;/g;			## HTML XSS safety transformations
	    $desc	=~ s/</&lt;/g;
	    $desc	=~ s/>/&gt;/g;
	    $content	.= join( "\n",
				 "<tr valign='top'>",
				 "<td><a href='$url/part/$part'>$part</a></td>",
				 "<td>$desc</td>",
				 "<td>",
				 "[<a href='$url/part/$part?format=xml'>xml</a>]",
				 "[<a href='$url/part/$part?format=json'>json</a>]",
				 "[<a href='$url/part/$part?format=text'>text</a>]",
				 "</td>",
				 "</tr>",
				 );
	}
	$content	.= join( "\n",
				 "</table>",
				 "<hr/>",
				 "<form action='$url' method='POST'>",
				 "<div>PART: <input type='text' name='part' value=''/> </div>",
				 "<div>DESC: <textarea name='desc' rows='5' cols='40'></textarea></div>",
				 "<div><input type='submit' name='create' value='Create New Part'/></div>",
				 "</form>",
				 "</body>",
				 "</html>",
				 );
    }
    elsif (exists( $data->{part} ))
    {
	my( $url )	= "http://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";
	$content	.= join( "\n",
				"<html>",
				"<body>",
				 "<div> NAVIGATION:",
				 "  <a href='$ENV{SCRIPT_NAME}'>All Parts</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}/api'>API</a>",
				 "  <hr/>",
				 "</div>",
				 "",
				 "<form action='$url/part/$data->{part}/delete' method='POST'>",
				 "<input type='hidden' name='delete' value='$data->{part}'/>",
				 "<div><input type='submit' value='Delete $data->{part}'/></div>",
				 "</form>",
				 "  <hr/>",
				 "",
				 "<form action='$url/part/$data->{part}/modify' method='POST'>",
				 "<div>PART: $data->{part}</div>",
				 "<div>DESC:<br/><textarea name='desc' rows='5' cols='60'>$data->{desc}</textarea></div>",
				 "<div><input type='submit' value='Update $data->{part}'/></div>",
				 "<input type='hidden' name='modify' value='$data->{part}'/>",
				 "</form>",
				 "",
				 "</body>",
				 "</html>",
				 );
    }
    elsif (exists( $data->{implementation} ))
    {
	my( $url )	= "http://$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}";
	$content	.= join( "\n",
				"<html>",
				"<body>",
				 "<div> NAVIGATION:",
				 "  <a href='$ENV{SCRIPT_NAME}'>All Parts</a> |",
				 "  <a href='$ENV{SCRIPT_NAME}/api'>API</a>",
				 "</div>",
				 "<h3>API: $data->{implementation}</h3>",
				 "<table border='1' cellpadding='5' cellspacing='1'>",
				 "<tr>",
				 "<th>API</th>",
				 "<th>Description</th>",
				 "</tr>",
				 "",
				 "<tr valign='top'>",
				 "<td>",
				 "<form action='$data->{PUT}->{url}/create' method='POST'>",
				 "<div>PART: <input type='text' name='part' value=''/></div>",
				 "<div>DESC:<br/><textarea name='desc' rows='5' cols='40'></textarea></div>",
				 "<div><input type='submit' value='Create New Part'/></div>",
				 "</form>",
				 "</td>",
				 "<td>$data->{PUT}->{description}</td>",
				 "</tr>",
				 "",
				 "<tr valign='top'>",
				 "<td>",
				 "<form action='$data->{GET}->{url}' method='GET'>",		## Use the modify under a specific part.
				 "<div>",
				 " PART: " . $this->_parts_list_select( "part" ),
				 " <input type='submit' value='Modify Existing Part'/>",
				 "</div>",
				 "</form>",
				 "</td>",
				 "<td>$data->{POST}->{description}</td>",
				 "</tr>",
				 "",
				 "<tr valign='top'>",
				 "<td>",
				 "<form action='$data->{DELETE}->{url}' method='POST'>",
				 "<div>",
				 "PART: " . $this->_parts_list_select( "delete" ),
				 "<input type='submit' value='Delete Existing Part'/>",
				 "</div>",
				 "</form>",
				 "</td>",
				 "<td>$data->{DELETE}->{description}</td>",
				 "</tr>",
				 "</table>",
				 "",
				 "<table border='1' cellpadding='5' cellspacing='1'>",
				 "<tr><th>MIME Type</th><th>Description</th></tr>",
				 );
	foreach my $format (sort keys %{ $this->{formats} } )
	{
	    $content .= "<tr><td>$format</td><td>$this->{descriptions}->{$format}</td></tr>";
	}
	$content	.= join( "\n",
				 "</table>",
				 "</body>",
				 "</html>",
				 );
    }
    else
    {
	$content .= join( "\n",
			  "Unhandled format condition:",
			  "<pre>",
			  Dumper( $data ),
			  "</pre>",
			  );
    }
    $content		.= join( "\n",
			 );
    return( $content );
}





#----------------------------------------------------------------------
=pod

=head2	_read()		- PRIVATE

USAGE:

    my( $content )	= $this->_read( $file );

DESCRIPTION:

    This method will read the file and return the contents to the
    caller or fail with an exception.

=cut

sub	_read
{
    my( $this )		= shift;
    my( $file )		= shift;
    my( $content )	= "";

    if  (open( FILE, $file ))
    {
	$content	= <FILE>;
	close( FILE );
	chmod( 0644, $file );
    }
    else
    {
	die "Unable to read [$file]: $!\n";
    }
    return( $content );
}





#----------------------------------------------------------------------
=pod

=head2	_write()		- PRIVATE

USAGE:

    $this->_write( $file, $content );

DESCRIPTION:

    This method will write $content to $file or fail with an
    exception.

=cut

sub	_write
{
    my( $this )		= shift;
    my( $file )		= shift;
    my( $content )	= shift;

    if  (open( FILE, ">$file" ))
    {
	print FILE $content;
	close( FILE );
	chmod( 0644, $file );
    }
    else
    {
	die "Unable to read [$file]: $!\n";
    }
}





#----------------------------------------------------------------------
=pod

=head2	_interrogate_request()	- PRIVATE

USAGE:

    my( $data )	= $this->_interrogate_request( $request_interface_instance );

DESCRIPTION:

    This method will attempt to pull all request parameters from the
    various places likely to pass them.

=cut

sub	_interrogate_request
{
    my( $this )		= shift;
    my( $cgi )		= shift;

    my( $method )	= $cgi->http( "REQUEST_METHOD" );		## Get the request method.
    my( @parts )	= split( "/", $cgi->http( "PATH_INFO" ) );
    shift( @parts );			## split( "/", "/part/$PART" ) => 3 items
    push( @parts, 1 )			if  (($#parts+1) % 2);		## /api becomes ("api" => 1)
    my( %request )	= @parts;
    my( $request )	= \%request;

    #
    #	Determine CRUD semantics.  Presume READ.
    #
    if    (defined( $request->{create} )  ||			## PATH_INFO.
	   defined( $cgi->param( "create" ) ))			## Via request.
    {
	$request->{create}	= 1;
	$request->{part}	= $cgi->param( "part" )		unless (defined( $request->{part} ));
	$request->{desc}	= $cgi->param( "desc" );
    }
    elsif    (defined( $request->{modify} ) ||		## PATH_INFO.
	      defined( $cgi->param( "modify" ) ))		## Via request.
    {
	$request->{modify}	= 1;
	$request->{part}	= $cgi->param( "part" )		unless (defined( $request->{part} ));
	$request->{desc}	= $cgi->param( "desc" );
    }
    elsif    (defined( $request->{delete} ) ||			## PATH_INFO.
	      defined( $cgi->param( "delete" ) ))		## Via request.
    {
	$request->{delete}	= 1;
	$request->{part}	= $cgi->param( "part" )		unless (defined( $request->{part} ));
    }
    elsif    (defined( $request->{api} ) ||			## PATH_INFO.
	      defined( $cgi->param( "api" ) ) ||		## Via request.
	      ($cgi->request_method() eq "HEAD") ||		## HEAD => api.
	      ($cgi->request_method() eq "TRACE"))		## TRACE => api.
    {
	$request->{api}		= 1;
    }
    else
    {
	$request->{read}	= 1;
	$request->{part}	= $cgi->param( "part" )		unless (defined( $request->{part} ));
	unless( defined( $request->{part} ) )
	{
	    $request->{parts}	= {};
	}
    }
    return( $request );
}





#----------------------------------------------------------------------
=pod

=head2	_parts_list_select()	PRIVATE

USAGE:

    print $this->_parts_list_select( $field_name );

DESCRIPTION:

    This method will generate a prepopulated select list named $name
    and return it to the caller.

=cut

sub	_parts_list_select
{
    my( $this )		= shift;
    my( $name )		= shift;
    my( $select )	= join( "\n",
				"<select name='$name'>",
				"<option value=''></option>",
				);
    opendir( DIRP, "./.data" );
    my( @entries )	= sort( readdir( DIRP ) );
    closedir( DIRP );
    foreach my $entry (@entries)
    {
	if  (-f "./.data/$entry")
	{
	    $select	.= "<option>$entry</option>\n";
	}
    }
    $select		.= "</select>\n";
    return( $select );
}



1;
