#----------------------------------------------------------------------
=pod

=head1	NAME

    REST::RequestFast

=head1	SYNOPSIS

    use REST::Resource;

    sub	main
    {
	my( $restul )	= new REST::Resource( request_interface => new REST::RequestFast() );
	...
    }

=head1	DESCRIPTION

This class provides a standardized interface shim that users can
implement in order to wrap around their favorite CGI::Fast interface
module so that it can be registered and used by REST::Resource.

If you prefer some module other than CGI.pm to access server-side CGI
behavior, then create a module that mimics this interface and register
it with REST::Resource as shown in the synopsis.

=head1	INTERFACE v. ABSTRACT BASE CLASS

In this case, I prefer Java's interface-style to an abstract base
class that someone must override.  Since this class derives from
CGI.pm for its implementation, you may not want that baggage in your
interface implementation.  Therefore, all you need to do is register a
class that provides the functionality specified by this module.

Since there isn't really a great Perl-based interface specification,
REST::Resource will interrogate your registered request_interface
to ensure that the class provides the minimum / required methods:

    new()
    http()
    param()
    header()

If you chose to provide an alternate interface implementation, these
are the methods that must exist before REST::Resource will accept your
interface.

=head1	AUTHOR

    John "Frotz" Fa'atuai
    frotz@acm.org

=head1	INTERFACE METHODS

=cut

package REST::RequestFast;

use strict;
use warnings;
use base "CGI::Fast";

our( $VERSION )	= '0.5.2.4';	## MODULE-VERSION-NUMBER





#----------------------------------------------------------------------
=pod

=head2	new()

USAGE:

    my( $restful )	= new REST::Resource( request_interface => new REST::Request() );
    my( $request )	= new REST::Request();

DESCRIPTION:

This method constructs a new instance of the request object.  The
first usage shows how users should pass this into REST::Resource.  The
second usage shows how you might use this in your unit tests.

WARNING:

This constructor plays REST games with CGI.pm by detecting PUT or
DELETE and transforming the request (temporarily) to POST, then
reverting back to the original value before returning an instance.
This allows us to use all of the nice POST processing provided by
CGI.pm, but for PUT, and DELETE, not just POST.

=cut

sub	new
{
    my( $class )	= shift;
####    $class 		= ref( $class )			if  (ref( $class ));	## Impossible to call via an instance.

    my( $orig ) 	= $ENV{REQUEST_METHOD};
    $orig		= ""				unless( defined( $orig ) );
    $ENV{REQUEST_METHOD} = "POST"			if  ($orig =~ /PUT|DELETE/i);

    my( $this )		= $class->SUPER::new( @_ );

    $ENV{REQUEST_METHOD} = $orig			if  ($orig =~ /PUT|DELETE/i);
    return( $this );
}




#----------------------------------------------------------------------
=pod

=head2	http()

USAGE:

    my( $value )	= $request->http( $variable );

DESCRIPTION:

This method extracts the given CGI $variable from the underlying
$request and returns its $value.

=cut

sub	http
{
    my( $this )	= shift;
    my( $var )	= shift;

    my( $retval )	= ($ENV{$var} ||		## Exact name match.
			   $ENV{ uc( $var ) } ||	## Uppercase match.
			   $ENV{ lc( $var ) }		## Lowercase match.
			   );
    return( $retval );
}




#----------------------------------------------------------------------
=pod

=head2	header()

USAGE:

    $request->header( %args );

DESCRIPTION:

This interface method provides access to the CGI-response header
functionality.  This method will be called when you have the
collection of response headers that you want to pass down to your base
class.

=cut

sub	header()
{
    my( $this )	= shift;
    return( $this->SUPER::header( @_ ) );
}





#----------------------------------------------------------------------
=pod

=head2	param()

USAGE:

    my( $value ) = $request->param( $variable );

DESCRIPTION:

This method returns the $value of the CGI request parameter $variable.

=cut

sub	param
{
    my( $this )		= shift;
    return( $this->SUPER::param( @_ ) );
}



#----------------------------------------------------------------------
=pod

=head1	SEE ALSO

    CGI::Fast
    REST::Resource

=cut

1;
