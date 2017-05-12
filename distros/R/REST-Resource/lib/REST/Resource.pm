#----------------------------------------------------------------------
=pod

=head1	NAME

    REST::Resource	-- Provide base class functionality for RESTful servers.

=head1	SYNOPSIS

    package My::Rest::Resource;
    use base "REST::Resource";

    sub new
    {
        my( $class )	= shift;
        my( $this )	= $this->SUPER::new( @_ );
        $this->method( "PUT",	\&Create, "This method handles the creation of My::Rest::Resource." );
        $this->method( "GET",	\&Read,   "This method handles the reading of My::Rest::Resource." );
        $this->method( "POST",	\&Update, "This method handles the updating of My::Rest::Resource." );
        $this->method( "DELETE",\&Delete, "This method handles the deletion of My::Rest::Resource." );
    }

    sub	Create	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Read	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Update	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Delete	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }

    package main;
    use My::Rest::Resource;

    my( $restful )	= new My::Rest::Resource();
    $restful->handle_request();				## One-shot CGI Context

=head1	DESCRIPTION

    This is a fork of WWW::Resource 0.01.  The major changes are:

    [] Full OO implementation
    [] Overt abstract base class design
    [] Support of Perl 5.6
    [] Support for use with CGI interface.
    [] Support for HEAD and TRACE.
    [] Method / handler registration to better support
       application-semantics over REST-semantics.

=head1	METHOD REGISTRATION

HTTP method handlers should be members of your derived class and
expect $this (or $self) as the first parameter.

    sub	Create	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Read	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Update	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }
    sub	Delete	{ my( $this ) = shift;	my( $request_interface_instance ) = shift; ... }

=head1	REQUEST INTERFACE INSTANCE

$request_interface_instance is a wrapper for your favorite Common
Gateway Interface implementation.  Mine is CGI.pm for server-side
request interrogation and server-side response.

If you don't like this, create a class modeled after REST::Request and
register it with:

    my( $restful ) = new REST::Resource( request_interface => new My::REST::Request() );

The REST::Resource constructor will validate that My::REST::Request
implements the requisite methods new(), http(), param() and header()
and then only use these methods to interace with the Common Gateway
Interface variables.

=head1	REQUESTED RETURNED CONTENT-TYPE:

The requesting client is responsible for specifying the returned
Content-Type: header in one of two ways.

[] Via the "Accept: application/xml" HTTP header.
[] Via the CGI query parameter ?format=xml

The Accept: header is preferred as it is semantically cleaner, but the
CGI query parameter is also supported in recognition of the fact that
sometimes it is easier to affect the request URL than it is to get at
and specify the HTTP headers.

=head1	DEFAULT SUPPORTED CONTENT TYPES

The supported content types provided by the base class are:

[]	?format=xml	or	Accept: application/xml
[]	?format=json	or	Accept: text/javascript
[]	?format=html	or	Accept: text/html

HTML will be returned if the requestor appears to be a browser and no
format is specified.

XML will be returned if the requestor does NOT appear to be a browser
and no format is specified.

=head1	AUTHOR

frotz@acm.org				Fork of WWW::Resource into REST::Resource.

=head1	CREDITS

Ira Woodhead <ira at sweetpota dot to>	For his WWW::Resource implementation.

=head1	BUGS

In the spirit of Transparency, please use rt.cpan.org to file bugs.
This way everyone can see what bugs have been reported and what their
status is and hopefully the fixed-in release.

=head1	METHODS

=cut

package REST::Resource;

use strict;			## Strict coding standards
use warnings;			## Very strict coding standards

use CGI	qw( :standard );
use HTTP::Status;		## Mneumonic HTTP Status codes.
use Data::Dumper;		## Output format: HTML
use REST::Request;		## Conditional CGI Request Support

eval "use XML::Dumper; 		import XML::Dumper; ";		## Conditional Output format: XML
eval "use JSON;        		import JSON; ";			## Conditional Output format: JavaScript Object Notation

our( $VERSION )	= '0.5.2.4';	## MODULE-VERSION-NUMBER




#----------------------------------------------------------------------
=pod

=head2	new()

USAGE:

    my( $restful ) = new REST::Resource();
    $restful->method( "GET", \&get_handler );
    $restful->handle_request();

    my( $restful ) = new REST::Resource( request_interface => new REST::Request() );

DESCRIPTION:

Create an instance of a REST::Resource, or one of its derived classes.

If you need a specific implementation of the REST::Request interface,
pass it in as shown in the second constructor call.

=cut

sub	new
{
    my( $class )	= shift;
    $class 		= ref( $class )			if  (ref( $class ));
    my( %args )		= @_;
    my( $args )		= \%args;
    my( $this )		= bless( {}, $class );

    unless  (exists( $args->{request_interface} ))
    {
	$args->{request_interface}	= new REST::Request();
    }
    my( $request )	= $args->{request_interface};
    unless  (UNIVERSAL::can( $request, "http" ))
    {
	die( "Interface [$args->{request_interface}] does not implement required method: http()\n" );
    }
    unless  (UNIVERSAL::can( $request, "param" ))
    {
	die( "Interface [$args->{request_interface}] does not implement required method: param()\n" );
    }
    unless  (UNIVERSAL::can( $request, "header" ))
    {
	die( "Interface [$args->{request_interface}] does not implement required method: header()\n" );
    }
    $this->{request_interface}	= $request;

    $this->{methods}	= {};
    $this->{formats}	= {};
    $this->{descriptions} = {};

    $this->{mimetype_mapping}	=
    {
	"html"		=> "text/html",
	"text/html"	=> "text/html",

	"text"		=> "text/plain",
	"text/plain"	=> "text/plain",
    };

    $this->method( "GET",		\&REST::Resource::unimplemented, "GET: Unimplemented read accessor." );
    $this->method( "PUT",		\&REST::Resource::unimplemented, "PUT: Unimplemented create mutator." );
    $this->method( "POST",		\&REST::Resource::unimplemented, "POST: Unimplemented update mutator." );
    $this->method( "DELETE",		\&REST::Resource::unimplemented, "DELETE: Unimplemented delete mutator." );
    $this->method( "TRACE",		\&REST::Resource::api, "TRACE: API identity / discoverability." );
    $this->method( "HEAD",		\&REST::Resource::api, "HEAD: API identity / discoverability." );
    $this->method( "authenticate",
		   \&REST::Resource::authenticate,
		   "authenticate: Default no-authorization-required authentication control implementation." );

    $this->format( "text/html",		\&REST::Resource::format_html, "Returns HTML UI.  Request via 'Accept: text/html' or '?format=html'" );
    $this->format( "text/plain",	\&REST::Resource::format_text, "Returns Text UI.  Request via 'Accept: text/plain' or '?format=text'" );
    if  (-f $INC{"XML/Dumper.pm"})
    {
	$this->{mimetype_mapping}->{xml} = "application/xml";		## Support: ?format=xml
	$this->format( "application/xml",
		       \&REST::Resource::format_xml,
		       "Returns generic XML.  Request via 'Accept: application/xml' or '?format=xml'" );
    };
    if  (-f $INC{"JSON.pm"})
    {
	$this->{mimetype_mapping}->{json} = "text/javascript";		## Support: ?format=json
	$this->format( "text/javascript",
		       \&REST::Resource::format_json,
		       "Returns Javascript Object Notation (JSON).  Request via 'Accept: text/javascript' or '?format=json'" );
    };
    if  (-f $INC{"REST/RequestFast.pm"})
    {
	$this->{ttl}	= 60 * 60;
    }
    return( $this );
}





#----------------------------------------------------------------------
=pod

=head2	run()		CAUTION

USAGE:

    my( $restful )	= new REST::Resource( request_interface => new REST::RequestFast() );
    $restful->run();

    my( $restful )	= new Your::WWW::Resource::Implementation( new REST::RequestFast() );
    $restful->run();

DESCRIPTION:

This method will run a REST::RequestFast instance.  It delegates
request interpolation to the registered request instance via the
constructor.  The default is a shim derived class of CGI.pm.

WWW::RESOURCE COMPATIBILITY:

If your derived class provides the WWW::Resource suggested callbacks
browserprint() and ttl(), this method will honor those and fold in the
new code hook mechanism.

WARNING:

If your derived class contains the method "browserprint()", the
calling semantics for _all_ methods will be \%query.

    $instance->$method( \%query_hash );

If your derived class does NOT contain the method "browserprint()", it
is assumed that you are using the new calling semantics where you
method handler is passed the request instance.

    $instance->$method( $request_instance );

Thus ref( $arg ) will be "HASH" for the old style and an object
reference for the new style.

=cut

sub	run
{
    my( $this )	= shift;

    eval
    {
	use REST::RequestFast;			## Conditional environment fun and games.
    };
    if  (-f $INC{"REST/RequestFast.pm"})
    {
	my( $html )	= $this->can( "browserprint" );						## WWW::Resource signature method.
	my( $ttl )	= $this->can( "ttl" );
	$this->format( "html", $html, "WWW::Resource style html-format handler." )	if  ($html);
	$this->{ttl}	= $this->ttl()						if  ($ttl);
	$this->{starttime}	= time();

	my( $cgi );
	while( ($cgi = new REST::RequestFast()) )
	{
	    my( $authenticate )	= $this->method( "authenticate" );
	    my( $status, $data )= $this->$authenticate( $cgi );				## We presume that $authenticate always exists.
	    if  ($status == RC_OK)
	    {
		my( $method )	= $this->method( $cgi->http( "REQUEST_METHOD" ) );
		if  ($html)									## WWW::Resource 0.01 semantics detected.
		{
		    my( %query )	= map { split /=/ } split /;/, lc( $ENV{QUERY_STRING} );## Gratuitous case mangling.
			$this->_return_result( $cgi, $this->$method->( \%query ) );		## Old calling convention.
		}
		else
		{
		    $this->_return_result( $cgi, $this->$method( $cgi ) );			## New calling convention.
		}
	    }
	    else
	    {
		$this->_return_result( $cgi, $status, $data );
	    }
	    if ( (time() - $this->{starttime}) > $this->{ttl} )
	    {
		return;
	    }
	}
    }
    else
    {
	die "REST::RequestFast did not load.  Presumably CGI::Fast and FCGI are unavailable.";
    }
}




#----------------------------------------------------------------------
=pod

=head2	handle_request()

USAGE:

    my( $restful ) = new REST::Resource( request_instance => new REST::Request() );
    $restful->handle_request();				## Implicit
    $restful->handle_request( new REST::Request() );	## Explicit
    $restful->handle_request( new CGI() );		## Explicit

DESCRIPTION:

This method runs a single action handler.  Optionally pass in the CGI
request to be handled.

=cut

sub	handle_request
{
    my( $this )		= shift;
    my( $req )		= shift;
    $req		= $this->get_request()				unless( $req );
    my( $method )	= $this->method( $req->http( "REQUEST_METHOD" ) );
    my( $authenticate )	= $this->method( "authenticate" );
    my( $status, $data )= $this->$authenticate( $req );			## We presume that $authenticate always exists.
    if  ($status == RC_OK  && defined( $method ))
    {
	$this->_return_result( $req, $this->$method( $req ) );
    }
    else
    {
	$this->_return_result( $req, $status, $data );			## Either 401/403
    }
}




#----------------------------------------------------------------------
=pod

=head2	method()

USAGE:

    my( $coderef ) = $restful->method( "GET" );		## OR
    my( $method )  = $restful->method( "GET", \&get_handler, $description );

    $restful->$method( $request_interface_instance );

DESCRIPTION:

This accessor/mutator allows the caller to register or change the
implementation behavior for a given HTTP method handler.  The standard
event handlers that are pre-registered are:

    GET
    PUT
    POST
    DELETE
    TRACE
    HEAD

Additionally, the following pseudo-methods provide over-ride control
to derived class implementors.

    authenticate

Unless otherwise overridden, the default implementation for each of
these methods is REST::Resource->unimplemented().

=cut

sub	method
{
    my( $this )			= shift;
    my( $method )		= shift;
    my( $implementation )	= shift;
    my( $description )		= shift;
    $description		= "$method: No API semantics provided during method registration."	unless( $description );
    my( $old )			= $this->{methods}->{$method} || undef;
    if  (defined( $implementation ))
    {
	$this->{methods}->{$method} 		= $implementation;
	$this->{descriptions}->{$method}	= $description;
    }
    return( $old );
}





#----------------------------------------------------------------------
=pod

=head2	format()

USAGE:

    my( $format ) = $restful->format( "xml" );		## OR
    $description   = $restful->format( "xml", \&format_xml, $description );

    $restful->$format( $request_interface_instance, $status, $data );

DESCRIPTION:

This accessor/mutator allows the caller to register or change the
implementation behavior for a given output format.

=cut

sub	format
{
    my( $this )			= shift;
    my( $format )		= shift;
    $format			= $this->{mimetype_mapping}->{$format}		if (exists( $this->{mimetype_mapping}->{$format} ));
    my( $implementation )	= shift;
    my( $description )		= shift;
    $description		= "$format: No format semantics provided during format registration."	unless( $description );
    my( $old )			= undef;
    $old			= $this->{formats}->{$format}		if  (exists( $this->{formats}->{$format} ));
    if  (defined( $implementation ))
    {
	$this->{formats}->{$format}		= $implementation;
	$this->{descriptions}->{$format}	= $description;
	$this->{mimetype_mapping}->{$format}	= $format;
    }
    return( $old );
}





#----------------------------------------------------------------------
=pod

=head2	description()

USAGE:

    my( $restful )	= new REST::Resource();
    my( $description )	= $restful->description( $name );

DESCRIPTION:

This accessor/mutator allows the caller to register or change the
description for a given HTTP method handler or output format.

This is used by REST::Resource->api() to provide a description of the
API.

PARAMETERS:

    $type	-- "methods" or "formats"
    $name	-- See the names appropriate for the given $type.
    $description-- The description to be set (or returned).

=cut

sub	description
{
    my( $this )		= shift;
    my( $name )		= shift;
    my( $description )	= "No description is available for [$name].";
    if  (defined( $this->{descriptions}->{$name} ))
    {
	$description = $this->{descriptions}->{$name};
    }
    return( $description );
}





#----------------------------------------------------------------------
=pod

=head2	api()

USAGE:

    my( $status, $data ) = $this->api( $request_interface_instance );

DESCRIPTION:

This method generates a resultset that can be returned through
$this->_return_result( $status, $data );

=cut

sub	api
{
    my( $this )	 	= shift;
    my( $req )		= shift;	## Interface: REST::Request
    my( $status )	= RC_OK;
    my( $data )		=
    {
	version		=> $this->VERSION,
	implementation	=> ref( $this ),
    };
    my( $server_url )	= ($req->http( "SERVER_PORT" ) == 443
			   ? "https://" . $req->http( "SERVER_NAME" )
			   : "http://" . $req->http( "SERVER_NAME" )
			   );
    my( $uri )		= (defined( $req->http( "SCRIPT_NAME" ) )
			   ? $req->http( "SCRIPT_NAME" )
			   : "/dummy/testing/uri");
    foreach my $method (keys( %{ $this->{methods} } ))
    {
	my( $api )		= {};
	$api->{url}		= $server_url . $uri;
	$api->{description}	= $this->description( $method );
	$data->{$method}	= $api;
    }
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	authenticate()

USAGE:

    my( $status, $data ) = $this->authenticate( $request_interface_instance );

DESCRIPTION:

This method may be overridden by a derived class that requires
HTTP request authentication.

STATUS VALUES:

    RC_OK		(200)	-- Accept provided credentials, if any.
    RC_UNAUTHORIZED	(401)	-- Prompt user for credentials via dialog box.
    RC_FORBIDDEN	(403)	-- Reject provided credentials.

DERIVED IMPLEMENTATIONS:

This method may be overridden in the derived class in order to
require a specific set of credentials.

=cut

sub	authenticate
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= RC_OK;
    my( $data )		= undef;

    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	format_xml()

USAGE:

    print $this->format_xml( $request_interface_instance, $status, $data );

DESCRIPTION:

This method will format $data as XML via XML::Dumper with an included
in-document DTD.  This method will only be registered if the module
XML::Deumper is found in the execution environment.

=cut

sub	format_xml
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;
    my( $xml )		= new XML::Dumper();
    $xml->dtd;					## Include an in-document DTD
    return( join( "",
		  $req->header( -status		=> $status,
				-expires	=> "+15s",
				-content_type	=> "application/xml" ),
		  $xml->pl2xml( $data ),
		  )
	    );
}





#----------------------------------------------------------------------
=pod

=head2	format_text()

USAGE:

    print $this->format_text( $request_interface_instance, $status, $data );

DESCRIPTION:

Use Data::Dumper to emit $data in text/plain format.

=cut

sub	format_text
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;
    return( join( "",
		  $req->header( -status => $status,
				-expires => "+15s",
				-content_type => "text/plain" ),
		  Dumper( $data ),
		  )
	    );
}





#----------------------------------------------------------------------
=pod

=head2	format_html()

USAGE:

    print $this->format_html( $request_interface_instance, $status, $data );

DESCRIPTION:

Use Data::Dumper to emit $data, then translate it via simple <pre>
tags with limited CSS to control the font-size.

=cut

sub	format_html
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;
    my( $dumped )	= substr( Dumper( $data ), 7 );
    return( join( "",
		  $req->header( -status => $status,
				-expires => "+15s",
				-content_type => "text/html" ),
		  "<html>",
		  "<head>",
		  "<title>Structured Data</title>",
		  "</head>",
		  "<body>",
		  "<h3>Structured Data</h3>",
		  "<pre style='font-size:0.8em; font-family:sans-serif;'>",	## 80% of normal size
		  $dumped,
		  "</pre>",
		  "</body>",
		  "</html>",
		  )
	    );
}





#----------------------------------------------------------------------
=pod

=head2	format_json()

USAGE:

    print $this->format_json( $request_interface_instance, $status, $data );

DESCRIPTION:

This method will format $data in JSON (JavaScript Object Notation).
This method will only be registered if JSON is found in the execution
environment.

=cut

sub	format_json
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;

    return( join( "",
		  $req->header( -status => $status,
				-expires => "+15s",
				-content_type => "text/javascript" ),
		  &objToJson( $data,
			      {
				  pretty => 1,
				  indent => 4,
			      }
			      )
		  )
	    );
}





#----------------------------------------------------------------------
=pod

=head2	unimplemented()

USAGE:

    N/A

DESCRIPTION:

This method is invoked if an unregistered HTTP REQUEST_METHOD is
invoked.

=cut

sub	unimplemented
{
    my( $this )		= shift;
    my( $req )		= shift;	## Interface: REST::Request
    my( $status )	= RC_OK;	## Don't let the browser whine.  We get to do that...
    my( $data )		=
    {
	ERROR		=> "No RESTful implementation defined for " . $req->http( "REQUEST_METHOD" ),
	RESOURCE	=> $req->http( "SCRIPT_NAME" ),
	PARAMETERS	=> $req->http( "PATH_INFO" ),
    };
    return( $status, $data );
}





#----------------------------------------------------------------------
=pod

=head2	default_format()

USAGE:

    my( $format )	= $this->default_format( $request_interface_instance );
    print $this->$format( $status, $data );

DESCRIPTION:

This method will return the requested format.  We look in two
places.  The first is in the query parameter list for the
parameter "format".  If that is defined, we return that value.

Otherwise, we scan through the list of q=1.0 Accept: headers and
return the first matching MIME-type.

SAMPLE OPERA Accept: / User-Agent: HEADERS:

    Accept: text/html, application/xml;q=0.9, application/xhtml+xml,
            image/png, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1
    User-Agent: Opera/9.10 (X11; Linux i686; U; en)

SAMPLE FIREFOX Accept: / User-Agent: HEADERS:

    Accept: text/xml, application/xml, application/xhtml+xml, text/html;
            q=0.9, text/plain;
            q=0.8, image/png, */*;
            q=0.5
    User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.3)
                Gecko/20070309 Firefox/2.0.0.3

SAMPLE MSIE Accept: / User-Agent: HEADERS:

    Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg,
            application/x-shockwave-flash, application/vnd.ms-powerpoint,
            application/vnd.ms-excel, application/msword, */*
    User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1;
                             .NET CLR 1.1.4322; .NET CLR 2.0.50727)

SUGGESTIONS FOR JSON DEVELOPERS:

Use "Accept: text/javascript" or "?format=json" to get JSON
output.  The default algorithm will presume that the client is a
human behind a browser and try to encourage html.

SUGGESTIONS FOR AJAX DEVELOPERS:

Use "Accept: application/xml" or "?format=xml" to get XML output.
The default algorithm will presume that the client is a human
behind a browser and try to encourage html.

=cut

sub	default_format
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $format )	= $req->param( "format" );
    my( $useragent )	= $req->http( "HTTP_USER_AGENT" );
    my( $accept )	= $req->http( "HTTP_ACCEPT" ) || ";";
    my( $explicit )	= (split( ";", $accept ))[0];		## Only q=1.0 entries

    if  (defined( $format ))
    {
	return( $format );
    }
    elsif (defined( $explicit ))
    {
	my( @mimetypes )	= split( /\,\s*/, $explicit );
	my( $mimetypes )	= {};
	foreach $format (@mimetypes)
	{
	    $mimetypes->{$format} = 1;
	}
	if (defined( $useragent ) &&
	    $useragent =~ /Gecko/i)
	{
	    return( "html" )	    if  ($mimetypes->{"text/html"} &&			## Firefox default is xml, but
					 $mimetypes->{"application/xml"});		## should be html.
	}
	foreach $format (@mimetypes)
	{
	    return( $format )	    if (exists( $this->{formats}->{$format} ));		## Return specified MIME-type.
	}
	if  (defined( $useragent ) &&
	     $useragent =~ /MSIE/)
	{
	    return( "html" );								## MSIE doesn't auto-match, so push HTML
	}
    }
    my( $default_type )	= "html";
    if  (defined( %XML::Dumper:: ))
    {
	$default_type	= "xml";
    }
    return( $default_type );
}





#----------------------------------------------------------------------
=pod

=head2	get_request()

USAGE:

    my( $request )	= $restful->get_request();

DESCRIPTION:

Return a new request_interface instance.  This instance must
support the methods: new(), http(), param() and header().

SEE ALSO:

    REST::Request
    REST::RequestFast

=cut

sub	get_request
{
    my( $this )		= shift;
    my( $interface )	= $this->{request_interface};
    return( $interface->new() );
}





#----------------------------------------------------------------------
=pod

=head2	_return_result()	PRIVATE

USAGE:

    $this->_return_result( $request_interface_instance, $http_status, $data );

DESCRIPTION:

This method is handed output of a given REQUEST_METHOD handler and is
responsible for appropriate status code emission and $data formatting.

=cut

sub	_return_result
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= shift;
    my( $data )		= shift;

    my( $status_msg )	= $status;
    $status_msg		.= &status_message( $status )		if (defined( $status ));
    chomp( $status_msg )					if (defined( $status_msg ));
    if ( &is_error( $status ))
    {
	print $req->header( -status => $status_msg );
    }
    else
    {
	my( $format ) = $this->default_format( $req );
	my( $formatter ) = $this->format( $format );
	print join( "",
		    $this->$formatter( $req, $status, $data ),
		    );
    }
}




#----------------------------------------------------------------------
=pod

=head2	SEE ALSO

    WWW::Resource
    http://www.peej.co.uk/articles/restfully-delicious.html
    http://www.xfront.com/REST-Web-Services.html
    http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm

=cut

1;
