# -*- Mode: Perl; -*-
package main;

no warnings "redefine";
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
    my( $tests )	= 13;
    my( @modules )	= ( "REST::Resource", "REST::RequestFast", "CGI::Fast", "FCGI" );
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

use REST::Resource;
use REST::RequestFast;
use IO::String;
use Data::Dumper;



&main();
exit( 0 );


#----------------------------------------------------------------------
#----------------------------------------------------------------------

package Mock::CGI;

use base "REST::RequestFast";

our( $requests )	= undef;

sub	new
{
    my( $class ) = "Mock::CGI";
    if  (defined( $requests ))
    {
	if  ($requests-- > 0)
	{
	    return( $class->SUPER::new( {'dinosaur'	=> 'barney',
					 'song'		=> 'I love you',
					 'friends'	=> [qw/Jessica George Nancy/] }
					) );
	}
	else
	{
	    return( undef );
	}
    }
    else
    {
	$requests = shift || 5;
	return( $class->SUPER::new( {'dinosaur'	=> 'barney',
				     'song'		=> 'I love you',
				     'friends'	=> [qw/Jessica George Nancy/] }
				    ) );
    }
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------
package	Rest::Test1;

use blib;
use base "REST::Resource";

sub	ttl
{
    return( 2 );
}

sub	my_responder
{
    my( $cgi )		= shift;
    my( $status )	= 404;
    my( $data )		= $cgi;

    return( $status, $data )
}

sub	authenticate
{
    my( $cgi )		= shift;
    my( $status )	= 401;
    my( $data )		= $cgi;

    return( $status, $data );
}

#----------------------------------------------------------------------
#----------------------------------------------------------------------

package	Rest::Test2;

use blib;
use base "REST::Resource";

sub	browserprint
{
    my( $this )	= shift;
    $this->format_html( @_ );
}

sub	my_responder
{
    my( $cgi )		= shift;
    my( $status )	= 200;
    my( $data )		= $cgi;

    return( $status, $data )
}

sub	authenticate
{
    my( $cgi )		= shift;
    my( $status )	= 200;
    my( $data )		= $cgi;

    return( $status, $data );
}
#----------------------------------------------------------------------
#----------------------------------------------------------------------

package main;

#----------------------------------------------------------------------
sub	main
{
    &test_request();
    &test_new();
    &test_run();
}

#----------------------------------------------------------------------
sub	test_new
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";
    my( $cgi )		= new Mock::CGI( 1 );
    ok( defined( $cgi ), "Constructor works via class name." );
}




#----------------------------------------------------------------------
sub	test_run
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/javascript";
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";

    $Mock::CGI::requests = 14;
    my( $cgi )		= new Mock::CGI(1);
    my( $restful )	= new Rest::Test1( request_interface => $cgi );
    $restful->method( "PUT", \&Rest::Test1::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    my( $start )	= time();
    my( $io_string )	= new IO::String();
    select( $io_string );
    $restful->run();
    my( $end )		= time();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "DELETE";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= new Rest::Test2( request_interface => $cgi );
    $restful->{ttl}	= 2;				## Cheat and peak inside but don't let the test stall for long.
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "DELETE", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "GET";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= new Rest::Test2( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "GET", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );


    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    $ENV{HTTP_ACCEPT}	= "q=1.0, text/html";
    $cgi		= new Mock::CGI(1);
    $restful		= $restful->new( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test2::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "POST", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    delete $ENV{HTTP_ACCEPT};
    $cgi		= new Mock::CGI(1);
    $restful		= $restful->new( request_interface => $cgi );
    $restful->method( "authenticate", \&Rest::Test1::authenticate, "Unit-test authentication handler for FCGI/run() testing." );
    $restful->method( "POST", \&Rest::Test2::my_responder, "Unit-test PUT handler for FCGI/run() testing." );
    $io_string		= new IO::String();
    select( $io_string );
    $restful->run();
    ok( ($end - $start) < 2, "FCGI server ended in an expected timeframe." );
}


#----------------------------------------------------------------------
sub	test_request
{
    $Mock::CGI::requests = 14;

    my( $cgi )		= new Mock::CGI(1);
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{bleech}	= "bar";
    $ENV{BLURFL}	= "BAR";
    ok( $cgi->http( "BLEECH" ) eq "bar", "Lowercase environment variable extraction." );
    ok( $cgi->http( "blurfl" ) eq "BAR", "Uppercase environment variable extraction." );
    ok( ! defined( $cgi->http( "Plugh" ) ), "Non-existent variable extraction." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "PUT";
    $cgi		= new Mock::CGI(3);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "PUT", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "DELETE";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "DELETE", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "GET";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "GET", "REQUEST_METHOD state change is undetectable, as expected." );

    $Mock::CGI::requests = 14;
    $ENV{REQUEST_METHOD}= "POST";
    $cgi		= new Mock::CGI(1);
    ok( defined( $cgi ) && $cgi->http( "REQUEST_METHOD" ) eq "POST", "REQUEST_METHOD state change is undetectable, as expected." );
}



1;
