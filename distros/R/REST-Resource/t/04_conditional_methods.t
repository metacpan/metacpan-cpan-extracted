# -*- Mode: Perl; -*-
package main;

no warnings;
use blib;
use Test::More;

#----------------------------------------------------------------------
=pod

DESCRIPTION:

    This BEGIN block will take the $test_count is registered for this
    file IFF the dependent modules can be loaded.  Because the CPAN
    automated test tools won't guarantee that my dependencies are
    loaded correctly, I have to do my own work to ensure that this
    module passes these broken automated tests.

    e.g. If no Makefile.PL is provided, an incorrect one is generated
    for me (against my desires) which results in a bad build
    environment and subsequent failed tests.

=cut

BEGIN
{
    my( $tests )	= 28;
    my( @modules )	= ( "XML::Dumper", "IO::String" );
    my( %files )	= {};
    my( $safe )		= 1;

    foreach my $module (@modules)
    {
	my( $file )	= $module;
	$file		=~ s/\:\:/\//g;
	$file		.= ".pm";
	$files->{ $file } = 0;
    }
    foreach my $file (sort keys %{ $files })
    {
	foreach my $dir (@INC)
	{
	    if  (-f ("$dir/$file"))
	    {
		$files->{$file} = 1;
	    }
	}
    }
    my( @reasons )	= "Conditional environment dependency avoidance:";
    foreach my $file (sort keys %{ $files })
    {
	$safe	= $safe && $files->{ $file };
	unless  ($files->{$file})
	{
	    push( @reasons, "\t$file not found on \@INC." );
	}
    }
    if  ($safe)
    {
	plan( tests => $tests );
    }
    else
    {
	plan( skip_all => join( " ", @reasons ) );
	exit( 0 );
    }
}

use Data::Dumper;
use XML::Dumper;
use IO::String;

use REST::Resource;
use REST::Request;


&main();
exit( 0 );

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_http;

sub	foo
{
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_param;

sub	http
{
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	bad::request_no_header;

sub	http
{
}

sub	param
{
}


#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	good::derived_resource;

use blib;
use base "REST::Resource";

sub	unauthorized
{
    my( $this )		= shift;
    my( $req )		= shift;
    my( $status )	= 401;		## Unauthorized
    my( $data )		= undef;

    return( $status, $data );
}


#----------------------------------------------------------------------
#----------------------------------------------------------------------

package main;

#----------------------------------------------------------------------
sub	main
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";
    my( $cgi )		= new REST::Request();
    my( $restful )	= new REST::Resource( request_interface => $cgi );
    ok( defined( $restful ), "Constructor works via class name." );
    my( $RESTful )	= $restful->new();
    ok( defined( $RESTful ), "Construct works via instance." );

    &test_formats( $restful, $cgi );
    &test_response( $restful, $cgi );
    &test_authentication( $cgi );
    &test_default_format_detection();
}




#----------------------------------------------------------------------
sub	test_formats
{
    my( $restful )	= shift;
    my( $cgi )		= shift;

    ok( $restful->format( "xml" )		eq \&REST::Resource::format_xml, "xml handler matches expectation" );
    ok( $restful->format( "application/xml" )	eq \&REST::Resource::format_xml, "application/xml handler matches expectation" );
    ok( $restful->format( "json" )		eq \&REST::Resource::format_json, "json handler matches expectation" );
    ok( $restful->format( "text/javascript" )	eq \&REST::Resource::format_json, "text/javascript handler matches expectation" );

    ok( $restful->description( "xml" ) =~ /xml/, "xml description matches expectation" );
    ok( $restful->description( "application/xml" ) =~ /Accept/, "application/xml description matches expectation" );

    ok( $restful->description( "json" ) =~ /json/, "json description matches expectation" );
    ok( $restful->description( "text/javascript" ) =~ /Accept/, "text/javascript description matches expectation" );

    $restful->format( "text/javascript", \&REST::Resource::format_json, "foo" );
    ok( $restful->description( "text/javascript" ) =~ /foo/, "text/javascript description matches expectation: " . $restful->description( "text/javascript" )  );

    ok( $restful->format_xml( $cgi, 200, { foo => "bar" } ) ne "", "format_xml() results match expectation." );
    ok( $restful->format_json( $cgi, 200, { foo => "bar" } ) ne "", "format_json() results match expectation." );

    $ENV{HTTP_ACCEPT}	= "application/xml, text/html, text/javascript, text/plain";
    ok( $restful->default_format( $cgi ) eq "application/xml", "Accept: application/xml; induced correct default format detection." );
    $ENV{HTTP_ACCEPT}	= "text/javascript, application/xml, text/html, text/plain";
    ok( $restful->default_format( $cgi ) eq "text/javascript", "Accept: text/javascript; induced correct default format detection." );

    $cgi->param( "format", "xml" );
    ok( $restful->default_format( $cgi ) eq "xml", "?format=xml; induced correct default format detection." );
    $cgi->param( "format", "json" );
    ok( $restful->default_format( $cgi ) eq "json", "?format=json; induced correct default format detection." );
}




#----------------------------------------------------------------------
sub	test_response
{
    my( $restful )	= shift;
    my( $cgi )		= shift;

    my( $io_string )	= new IO::String();
    my( $content )	= "";

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/plain";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\$VAR1/, "Data::Dumper output detected in text/plain response." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\$VAR1/, "JSON output detected in text/javascritp response." . $content );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\<html\>/, "HTML output detected in text/html response." . $content );

    $ENV{HTTP_ACCEPT}	= "q=1.0, application/xml";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\#REQUIRED/, "XML output detected in application/xml response." . $content );

    $ENV{REQUEST_METHOD}	= "blurfl";
    $io_string		= new IO::String();
    select( $io_string );
    $restful->handle_request();
    $content = Dumper( $io_string );
    ok( $content =~ /\#REQUIRED/, "XML output detected in spite of bad REQUEST_METHOD." . $content );
}



#----------------------------------------------------------------------
sub	test_authentication
{
    my( $cgi )		= shift;
    my( $io_string )	= new IO::String();
    my( $restful )	= new good::derived_resource();
    $restful->method( "authenticate", \&good::derived_resource::unauthorized, "401: Unauthorized behavior" );

    select( $io_string );
    $restful->handle_request( $cgi );
    ok( 1, "No failures executing handle_request with unauthorized behavior (weak test)." );
}







#----------------------------------------------------------------------
sub	test_default_format_detection
{
    my( $restful )	= new REST::Resource();
    my( $cgi )		= new REST::Request();
    $ENV{HTTP_ACCEPT}	= "q=1.0, application/xhtml+xml, application/xml";
    ok( $restful->default_format( $cgi ) eq "application/xml", "quality 1.0 application/xml default format detected." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, some/mimetype; q=0, other/mimetype";
    ok( $restful->default_format( $cgi ) eq "xml", "default xml default format presumed." );

    $ENV{HTTP_ACCEPT}	= "q=0.1, some/mimetype";
    ok( $restful->default_format( $cgi ) eq "xml", "default xml default format presumed." );

    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    ok( $restful->default_format( $cgi ) eq "text/javascript", "quality 1.0 text/javascript default format detected." );

    $ENV{HTTP_ACCEPT}	= undef;
    ok( $restful->default_format( $cgi ) eq "xml", "no accept header returns xml by default." );
}



1;

