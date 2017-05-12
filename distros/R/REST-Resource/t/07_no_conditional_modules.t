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
    my( $tests )	= 4;
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
use IO::String;

&main();
exit( 0 );


#----------------------------------------------------------------------
sub	main
{
    $ENV{REQUEST_METHOD}= "PUT";
    $ENV{REQUEST_URI}	= "/foo/bar";
    $ENV{SERVER_NAME}	= "localhost";
    $ENV{SERVER_PORT}	= 80;
    $ENV{SCRIPT_NAME}	= "/foo.pl";
    $ENV{PATH_INFO}	= "/bar";

    $INC{ "XML/Dumper.pm" }		= 1;	## Preclude XML::Dumper from loading.
    $INC{ "JSON.pm" } 			= 1;	## Preclude JSON from loading.
    $INC{ "REST/RequestFast.pm" }	= 1;	## Preclude JSON from loading.

    eval "use REST::Resource;";			## Defer compile-time load.
    eval "use REST::RequestFast;";		## Defer compile-time load.

    &test_no_xml_dumper();
    &test_no_json();
    &test_no_rest_requestfast();
}




#----------------------------------------------------------------------
sub	test_no_xml_dumper
{
    my( $restful )	= new REST::Resource();
    ok( ! exists( $restful->{mimetype_mapping}->{xml} ), 		"XML::Dumper hooks not loaded when not available, as expected." );
    ok( ! exists( $restful->{mimetype_mapping}->{"application/xml"} ),	"XML::Dumper hooks not loaded when not available, as expected." );
}


#----------------------------------------------------------------------
sub	test_no_json
{
    my( $restful )	= new REST::Resource();
    ok( ! exists( $restful->{mimetype_mapping}->{json} ), 		"JSON hooks not loaded when not available, as expected." );
    ok( ! exists( $restful->{mimetype_mapping}->{"text/javascript"} ),	"JSON hooks not loaded when not available, as expected." );
}


#----------------------------------------------------------------------
sub	test_no_rest_requestfast
{
    eval
    {
	my( $restful )	= new REST::Resource( request_interface => new REST::RequestFast() );
    };
    eval
    {
	my( $restful )	= new REST::Resource();
	$restful->run();
    };
}


1;

