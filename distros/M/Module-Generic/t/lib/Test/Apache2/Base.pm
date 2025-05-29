## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/t/lib/Test/Apache2/Base.pm
## Version v0.1.1
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/05/05
## Modified 2025/05/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Test::Apache2::Base;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use Apache::TestConfig;
    use APR::Table ();
    use APR::URI ();
    use Module::Generic::File qw( file );
    use Scalar::Util;
};

use strict;
use warnings;

our $config = Apache::TestConfig->thaw->httpd_config;
our $class2log = {};

sub process
{
    my $self = shift( @_ );
    die( "process() should be called with an object, not as $self->process" ) if( !ref( $self ) );
    my $class = ref( $self );
    my $r = $self->{request};
    if( !$r )
    {
        die( "${class}: No Apache2::RequestRec object was set in our class $class" );
    }
    elsif( !Scalar::Util::blessed( $r ) )
    {
        die( "${class}: The request object provided (", overload::StrVal( $r // 'undef' ), ") was not a blessed reference." );
    }
    elsif( !$r->isa( 'Apache2::RequestRec' ) )
    {
        die( "${class}: The request object provided (", overload::StrVal( $r // 'undef' ), ") is not an Apache2::RequestRec" );
    }
    my $debug = $r->dir_config( 'MG_DEBUG' );
    $r->log_error( "${class}: Received request for uri \"", $r->uri, "\" matching file \"", $r->filename, "\": ", $r->as_string ) if( $debug );
    my $uri = APR::URI->parse( $r->pool, $r->uri );
    my $path = [split( '/', $uri->path )]->[-1];
    my $code = $self->can( $path );
    if( !defined( $code ) )
    {
        $r->log_error( "${class}: No method \"$path\" for testing." );
        return( Apache2::Const::DECLINED );
    }
    $r->err_headers_out->set( 'Test-No' => $path );
    my $rc = $code->( $self );
    $r->log_error( "$class: Returning HTTP code '$rc' for method '$path'" ) if( $debug );
    if( $rc == Apache2::Const::HTTP_OK )
    {
        # https://perl.apache.org/docs/2.0/user/handlers/intro.html#item_RUN_FIRST
        # return( Apache2::Const::DONE );
        return( Apache2::Const::OK );
    }
    else
    {
        return( $rc );
    }
    # $r->connection->client_socket->close();
    exit(0);
}

sub debug
{
    my $self = shift( @_ );
    $self->{debug} = shift( @_ ) if( @_ );
    return( $self->{debug} );
}

sub error
{
    my $self = shift( @_ );
    my $r = $self->request;
    $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    my $ref = [@_];
    my $error = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) );
    warn( $error );
    $r->log_error( $error );
    $r->print( $error );
    $r->rflush;
    return;
}

sub failure { return( shift->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => 'failed' ) ); }

sub is
{
    my $self = shift( @_ );
    my( $what, $expect ) = @_;
    return( $self->success ) if( $what eq $expect );
    return( $self->reply( Apache2::Const::HTTP_EXPECTATION_FAILED => "failed\nI was expecting \"$expect\", but got \"$what\"." ) );
}

sub message
{
    my $self = shift( @_ );
    return unless( $self->{debug} );
    my $class = ref( $self );
    my $r = $self->request || return( $self->error( "No Apache2::RequestRec object set!" ) );
    my $ref = [@_];
    my $sub = (caller(1))[3] // '';
    my $line = (caller())[2] // '';
    $sub = substr( $sub, rindex( $sub, ':' ) + 1 );
    $r->log_error( "${class} -> $sub [$line]: ", join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @$ref ) ) );
    return( $self );
}

sub ok
{
    my $self = shift( @_ );
    my $cond = shift( @_ );
    return( $cond ? $self->success : $self->failure );
}

sub reply
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my $r = $self->request;
    $r->content_type( 'text/plain' );
    $r->status( $code );
    $r->rflush;
    $r->print( @_ );
    return( $code );
}

sub reply_enhanced
{
    my $self = shift( @_ );
    my( $code, $ref );
    # $self->reply( Apache2::Const::HTTP_OK, { message => "All is well" } );
    if( scalar( @_ ) == 2 )
    {
        ( $code, $ref ) = @_;
    }
    elsif( scalar( @_ ) == 1 &&
        $self->_can( $_[0] => 'code' ) && 
        $self->_can( $_[0] => 'message' ) )
    {
        my $ex = shift( @_ );
        $code = $ex->code;
        $ref = 
        {
            message => $ex->message,
        };
    }
    # $self->reply({ code => Apache2::Const::HTTP_OK, message => "All is well" } );
    elsif( ref( $_[0] ) eq 'HASH' )
    {
        $ref = shift( @_ );
        $code = $ref->{code} if( CORE::length( $ref->{code} ) );
    }
    my $r = $self->request;
    my $j = JSON->new->utf8;
    if( $code !~ /^[0-9]+$/ )
    {
        $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $r->rflush;
        $r->print( $j->encode({ error => 'An unexpected server error occured', code => 500 }) );
        $self->error( "http code to be used '$code' is invalid. It should be only integers." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    if( ref( $ref ) ne 'HASH' )
    {
        $r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        $r->rflush;
        # $r->send_http_header;
        $r->print( $j->encode({ error => 'An unexpected server error occured', code => 500 }) );
        $self->error( "Data provided to send is not an hash ref." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    
    my $msg;
    if( CORE::exists( $ref->{success} ) )
    {
        $msg = $ref->{success};
    }
    # Maybe error is a string, or maybe it is already an error hash like { error => { message => '', code => '' } }
    elsif( CORE::exists( $ref->{error} ) && $code !~ /^2\d{2}$/ )
    {
        if( ref( $ref->{error} ) eq 'HASH' )
        {
            $msg = $ref->{error}->{message};
        }
        else
        {
            $msg = $ref->{error};
            $ref->{error} = {};
        }
        $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
        $ref->{error}->{message} = "$msg" if( !CORE::length( $ref->{error}->{message} ) && ( !ref( $msg ) || overload::Method( $msg => "''" ) ) );
        CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
        CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
    }
    elsif( CORE::exists( $ref->{message} ) )
    {
        $msg = $ref->{message};
        # We format the message like in bailout, ie { error => { message => '', code => '' } }
        if( $code =~ /^[45]\d{2}$/ )
        {
            $ref->{error} = {} if( ref( $ref->{error} ) ne 'HASH' );
            $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
            $ref->{error}->{message} = $ref->{message} if( !CORE::length( $ref->{error}->{message} ) );
            CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
            CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
        }
        else
        {
            # All is good already
        }
    }
    elsif( $code =~ /^[45]\d{2}$/ )
    {
        $ref->{error} = {} if( !CORE::exists( $ref->{error} ) || ref( $ref->{error} ) ne 'HASH' );
        $ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
        CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
    }

    my $frameOffset = 0;
    my $sub = ( caller( $frameOffset + 1 ) )[3];
    $frameOffset++ if( substr( $sub, rindex( $sub, '::' ) + 2 ) eq 'reply' );
    my( $pack, $file, $line ) = caller( $frameOffset );
    $sub = ( caller( $frameOffset + 1 ) )[3];
    # Without an Access-Control-Allow-Origin field, this would trigger an erro ron the web browser
    # So we make sure it is there if not set already
    unless( $r->err_headers_out->get( 'Access-Control-Allow-Origin' ) )
    {
        $r->err_headers_out->set( 'Access-Control-Allow-Origin' => '*' );
    }
    # As an api, make sure there is no caching by default unless the field has already been set.
    unless( $r->err_headers_out->get( 'Cache-Control' ) )
    {
        $r->err_headers_out->set( 'Cache-Control' => 'private, no-cache, no-store, must-revalidate' );
    }
    $r->content_type( 'application/json' );
    # $r->status( $code );
    $r->status( $code );
    if( defined( $msg ) && $r->content_type ne 'application/json' )
    {
        # $r->custom_response( $code, $msg );
        $r->custom_response( $code, $msg );
    }
    else
    {
        # $r->custom_response( $code, '' );
        $r->custom_response( $code, '' );
        #$r->status( $code );
    }

    # We make sure the code is set
    if( CORE::exists( $ref->{error} ) && $code !~ /^2\d{2}$/ )
    {
        $ref->{error}->{code} = $code if( ref( $ref->{error} ) eq 'HASH' && !CORE::length( $ref->{error}->{code} ) );
    }
    else
    {
        $ref->{code} = $code if( !CORE::length( $ref->{code} ) );
    }

    if( CORE::exists( $ref->{cleanup} ) &&
        defined( $ref->{cleanup} ) &&
        ref( $ref->{cleanup} ) eq 'CODE' )
    {
        my $cleanup = CORE::delete( $ref->{cleanup} );
        # See <https://perl.apache.org/docs/2.0/user/handlers/http.html#PerlCleanupHandler>
        $r->pool->cleanup_register( $cleanup, $self );
        # $r->push_handlers( PerlCleanupHandler => $cleanup );
    }

    # Our print() will possibly change the HTTP headers, so we do not flush now just yet.
    my $json = $j->encode( $ref );
    # Before we use this, we have to make sure all Apache module that deal with content encoding are de-activated because they would interfere
    if( !$r->print( $json ) )
    {
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    $r->rflush;
    return( $code );
}

sub request { return( shift->{request} ); }

sub success { return( shift->reply( Apache2::Const::HTTP_OK => 'ok' ) ); }

sub _can
{
    my $self = shift( @_ );
    no overloading;
    # Nothing provided
    return if( !scalar( @_ ) );
    return if( !defined( $_[0] ) );
    return if( !Scalar::Util::blessed( $_[0] ) );
    if( $self->_is_array( $_[1] ) )
    {
        foreach my $meth ( @{$_[1]} )
        {
            return(0) unless( $_[0]->can( $meth ) );
        }
        return(1);
    }
    else
    {
        return( $_[0]->can( $_[1] ) );
    }
}

sub _request { return( shift->{request} ); }

sub _object { return( shift->{_object} ); }

sub _test
{
    my $self = shift( @_ );
    my $opts = shift( @_ );
    die( "Argument provided is not an hash reference." ) if( ref( $opts ) ne 'HASH' );
    my $class = ref( $self );
    my $r = $self->request || die( "No Apache2::RequestRec is set." );
    my $debug = $self->debug;
    my $meth = $opts->{method};
    if( !$meth )
    {
        $r->log_error( "${class}: no method provided to test." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    # expect may be undef
    if( !exists( $opts->{expect} ) )
    {
        $r->log_error( "${class}: no expected value provided to test method '$meth'." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $expect = $opts->{expect};
    my $args = exists( $opts->{args} ) ? $opts->{args} : undef;
    $opts->{type} //= '';
    my $obj = $self->_object;
    if( !$obj )
    {
        $r->log_error( "${class}: Cannot get a target object." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $obj_class = ref( $obj );
    my $code = $obj->can( $meth );
    if( !$code )
    {
        $r->log_error( "${class}: Method '$meth' is not supported in ${obj_class}." );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $base_path;
    unless( $base_path = $class2log->{ ref( $obj ) } )
    {
        my @parts = split( /::/, ref( $obj ) );
        my $parent_path = $config->{vars}->{t_logs} || die( "No 't_logs' variable in Apache::TestConfig->thaw->httpd_config" );
        $parent_path = file( $parent_path );
        $base_path = $parent_path->child( join( '/', map( lc( $_ ), split( /::/, $obj_class ) ) ) );
        $base_path->mkpath if( !$base_path->exists );
        $class2log->{ $obj_class } = $base_path;
    }
    my $log_file = $base_path->child( "${meth}.log" );
    my $io = $log_file->open( '>', { autoflush => 1, binmode => 'utf8' } ) || 
        die( "Unable to open test log file \"$log_file\" in write mode: $!" );
    
    my $val = $args ? $code->( $obj, @$args ) : $code->( $obj );
    my $rv;
    if( ref( $expect ) eq 'CODE' )
    {
        $rv = $expect->( $val, { object => $self, log => sub{ $io->print( @_, "\n" ) } } );
    }
    elsif( $opts->{type} eq 'boolean' )
    {
        $rv = ( int( $val // '' ) == $expect );
        if( !$rv )
        {
            $io->print( "Boolean value expected (", ( $expect // 'undef' ), "), but got '", int( $val // '' ), "'\n" );
        }
    }
    elsif( $opts->{type} eq 'isa' )
    {
        $rv = ( Scalar::Util::blessed( $val ) && $val->isa( $expect ) );
        if( !$rv )
        {
            $io->print( "Object of class '", ( $expect // 'undef' ), "', but instead got '", ( $val // 'undef' ), "'\n" );
        }
    }
    else
    {
        if( !defined( $val ) )
        {
            $rv = !defined( $expect );
            if( !$rv )
            {
                $io->print( "Expected a defined value (", ( $expect // 'undef' ), "), but instead got an undefined one.\n" );
            }
        }
        elsif( !defined( $expect ) )
        {
            $rv = 0;
            if( !$rv )
            {
                $io->print( "Expected an undefined value, but instead got a defined one (", ( $val // 'undef' ), ").\n" );
            }
        }
        else
        {
            $rv = ( $val eq $expect );
            if( !$rv )
            {
                $io->print( "Expected the value to be '", ( $expect // 'undef' ), "', but instead got '", ( $val // 'undef' ), "'\n" );
            }
        }
    }
    $io->close;
    $log_file->remove if( $log_file->is_empty );
    $r->log_error( "${class}: ${meth}() -> ", ( $rv ? 'ok' : 'not ok' ) ) if( $debug );
    return( $self->ok( $rv ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Test::Apache2::Base - Apache2 Module::Generic Testing Base Class

=head1 SYNOPSIS

    package Test::Apache2::API;
    use parent qw( Test::Apache2::Base );
    # etc.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package to inherit from for the test modules.

=head1 METHODS

=head2 process

This is the main method called by the Apache handler to call the right method based on the URI called.

Then, it returns either C<Apache2::Const::OK> upon success, or whatever HTTP code the method called returns.

=head2 debug

Sets or gets the debug value.

=head2 error

    $self->error( "This failed big time." );

Provided with an error, and this logs it to the Apache error log, and print it on the C<STDOUT> as well.

A message passed to C<error> can be a list of strings, and code reference that will be executed by C<error> when collating them all.

=head2 failure

    sub my_method
    {
        my $self = shift( @_ );
        # Do some computation...
        # Returns a 417 error (HTTP expectation failed)
        return( $self->failure );
    }

Calls L</reply> with C<Apache2::Const::HTTP_EXPECTATION_FAILED> and C<failed> and returns its value, which is the HTTP code.

=head2 is

    sub my_test
    {
        my $self = shift( @_ );
        my $rv = $self->some_method;
        return( $self->is( $rv => $expect ) );
    }

Provided with a resulting value and an expected value and this returns C<ok> by calling L</success> if both match, or an error with code C<417> (HTTP expectation failed), and a string explaining the failure to match.

=head2 message

    $self->message( "This is ", "working well. Here is the result: ", sub{ Data::Pretty::dump( $hash ) } );

This does nothing unless L</debug> is set to an integer higher than 0.

It takes a list of strings that it concatenates, and print it to the Apache error log.

As part of the list of string, it also accepts code references that will be executed, and their returned value added to the string.

=head2 ok

    sub my_test
    {
        my $self = shift( @_ );
        my $rv = $self->some_method;
        return( $self->ok( $rv ) );
    }

Provided with a boolean value, and this returns the value returned by L</success> or L</failure> otherwise.

=head2 reply

    $self->reply( Apache2::Const::HTTP_OK => "Oh well. ", "Maybe this will work ?" );

Would print out an HTTP response:

    HTTP/1.1 200 OK
    Content-type: text/plain

    Oh well. Maybe this will work ?

Provided with a response HTTP code and some text data, and this will return the response to the http client.

In a method, this needs to be called and returned, such as:

    sub my_test
    {
        my $self = shift( @_ );
        my $rv = $self->some_method;
        return( $self->reply( Apache2::Const::HTTP_BAD_REQUEST => "Nope, it failed..." ) );
    }

=head2 reply_enhanced

    sub my_test
    {
        my $self = shift( @_ );
        my $rv = $self->some_method;
        return( $self->reply( Apache2::Const::HTTP_BAD_REQUEST => { message => "Nope, it failed..." } ) );
    }

This is the same as L</reply>, except it takes an hash reference instead of a list of strings. The hash reference will then be transformed into a JSON payload before being sent back.

C<reply_enhanced> will set the property C<code> to the HTTP code for you, and if the HTTP code is an error, the JSON payload will contain the property C<error> instead of C<message>

=head2 request

Returns the L<Apache2::RequestRec> object.

=head2 success

    sub my_test
    {
        my $self = shift( @_ );
        my $rv = $self->some_method;
        # Yeah, all is good !
        return( $self->success );
    }

Calls L</reply> with C<Apache2::Const::HTTP_OK> and C<ok> and returns its value, which is the HTTP code.

=head2 _object

Returns the object to be used to make method calls during tests. This is used by L</_test>

=head2 _test

    sub my_test { return( shift->_test({ method => 'some_method', expect => $some_value }) ); }

or

    sub json { return( shift->_test({ method => 'json', expect => sub
    {
        my $json = shift( @_ );
        return( Scalar::Util::blessed( $json ) && 
                   $json->isa( 'JSON' ) && 
                   $json->canonical && 
                   $json->get_relaxed && 
                   $json->get_utf8 && 
                   $json->get_allow_nonref && 
                   $json->get_allow_blessed && 
                   $json->get_convert_blessed );
    }, args => [pretty => 1, ordered => 1, relaxed => 1, utf8 => 1, allow_nonref => 1, allow_blessed => 1, convert_blessed => 1] }) ); }

This takes an hash reference of options, and performs the test by calling the method C<method> using the object retrieved from L<_object|/object>, compare it against expected result, and return an appropriate response to the user.

It accepts the following properties:

=over 4

=item * C<args>

An optional array reference of arguments to pass to the method C<method>

=item * C<expect>

The expected resulting value.

This can be a scalar, or a subroutine reference.

If a subroutine reference was provided, it will be called, passing it the value returned by the method call.

=item * C<method>

The method to call using the object retrieved from L<_object|/_object>

=item * C<type>

Specifies the type of operation to perform when checking the result against the expected value.

Possible value are:

=over 8

=item * C<boolean>

The value returned from the method call will be converted to an integer and then compared to the expected value.

    sub has_error { return( shift->_test({ method => 'has_error', expect => 1, type => 'boolean' }) ); }

=item * C<isa>

    # Expecting call to 'my_method' to return a blessed reference from a class that inherits 'Other::Package'
    return( shift->_test({ method => 'my_method', type => 'isa', 'expect' => 'Other::Package' });

This will check that the returned value from the method call is a blessed reference that is an object of the class specified by C<expect>

=back

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic>, L<Apache2::API::Request>, L<Apache2::API::Response>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
