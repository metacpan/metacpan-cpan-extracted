## -*- perl -*-
##----------------------------------------------------------------------------
## Module Generic - ~/t/lib/Test/Apache2/MG.pm
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
package Test::Apache2::MG;
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use parent qw( Test::Apache2::Base );
    use Apache2::Connection ();
    use Apache2::Const -compile => qw( :common :http OK DECLINED );
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    # so we can get the request as a string
    use Apache2::RequestUtil ();
    use Apache2::Response ();
    use APR::Table ();
    use APR::URI ();
    use JSON;
    use Module::Generic;
    use Module::Generic::Global;
    use Scalar::Util;
    # 2021-11-1T17:12:10+0900
    use Test::Time time => 1635754330;
    use constant HAS_SSL => ( $ENV{HTTPS} || ( defined( $ENV{SCRIPT_URI} ) && substr( lc( $ENV{SCRIPT_URI} ), 0, 5 ) eq 'https' ) ) ? 1 : 0;
};

use strict;
use warnings;

sub handler : method
{
    my( $class, $r ) = @_;
    my $debug = int( $r->dir_config( 'MG_DEBUG' ) // 0 );
    $r->log_error( "$class: MG_DEBUG value set to '$debug'" );
    Apache2::RequestUtil->request( $r );
    Module::Generic::Global->cleanup_register( $r );
    # Call the inner module to instantiate a new object
    my $obj = MyObject->new( request => $r, debug => $debug );
    if( !$obj )
    {
        $r->log_error( "$class: Error instantiating Apache2::API object: ", MyObject->error );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $self = bless( { request => $r, _object => $obj, debug => $debug } => $class );
    return( $self->process );
}

sub dummy_error
{
    my $self = shift( @_ );
    my $obj = $self->_object || die( "No object." );
    $obj->error({ message => 'Oh no!', code => 400 });
    return( $self->reply_enhanced({ message => $obj->error->message, code => $obj->error->code }) );
}

sub has_modperl { return( shift->_test({ method => 'has_modperl', type => 'boolean', expect => 1 }) ); }

sub non_threaded_error
{
    my $self = shift( @_ );
    my $obj = $self->_object || die( "No object." );
    $obj->error({ message => 'Non-threaded error test', code => 400 });
    return( $self->reply_enhanced({ message => $obj->error->message, code => $obj->error->code }) );
}

sub threaded_error
{
    my $self = shift( @_ );
    my $obj = $self->_object || die( "No object." );
    $obj->error({ message => 'Threaded error test', code => 400 });
    return( $self->reply_enhanced({ message => $obj->error->message, code => $obj->error->code }) );
}

# Calling the method 'new_json' inherited from Module::Generic
sub json { return( shift->_test({ method => 'new_json', expect => sub
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

sub reply
{
    return( shift->reply_enhanced( Apache2::Const::HTTP_OK => {
        message => "ok",
    }) );
}

# NOTE: Hidden package MyObject
package
    MyObject;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'MyException';
    return( $self->SUPER::init( @_ ) );
}

sub has_modperl { return( exists( $ENV{MOD_PERL} ) && $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ ? 1 : 0 ); }

sub request { return( shift->_set_get_object_without_init( 'request', 'Apache2::RequestRec', @_ ) ); }

# NOTE: Add some methods here we want to test

# NOTE: class MyException
package
    MyException;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
};

1;
# NOTE: POD
# Use this to generate the tests list:
# egrep -E '^sub ' ./t/lib/Test/Apache2/MG.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "=head2 $m\n"'
__END__

=encoding utf8

=head1 NAME

Test::Apache2::MG - Apache2 Module::Generic Testing Class

=head1 SYNOPSIS

In the Apache test conf:

    PerlOptions +GlobalRequest
    PerlSetupEnv On
    <Directory "@documentroot@">
        SetHandler modperl
        PerlResponseHandler Test::Apache2::MG
        AcceptPathInfo On
    </Directory>

In the test unit:

    use Apache::Test;
    use Apache::TestRequest;
    use HTTP::Request;

    my $hostport = Apache::TestRequest::hostport( $config ) || '';
    my( $host, $port ) = split( ':', ( $hostport ) );
    my $mp_host = 'www.example.org';
    Apache::TestRequest::user_agent(reset => 1, keep_alive => 1 );
    my $ua = Apache::TestRequest->new;
    # To get the fingerprint for the certificate in ./t/server.crt, do:
    # echo "sha1\$$(openssl x509 -noout -in ./t/server.crt -fingerprint -sha1|perl -pE 's/^.*Fingerprint=|(\w{2})(?:\:?|$)/$1/g')"
    $ua->ssl_opts(
        # SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
        # SSL_verify_mode => 0x00
        # verify_hostname => 0,
        SSL_fingerprint => 'sha1$2FBAB657122088E11FA95E34C1BD9E3635EC535A',
        # SSL_version     => 'SSLv3',
        # SSL_verfifycn_name => 'localhost',
    );
    my $req = HTTP::Request->new( 'GET' => "${proto}://${hostport}/tests/api/some_test_name" );
    my $resp = $ua->request( $req );
    is( $resp->code, Apache2::Const::HTTP_OK, 'some test name' );

Then, create method that will be called to test the underlying object stored in C<_target>

For example, testing the method C<some_method> of the class C<MyModule>

    sub my_test { return( shift->_test({ method => 'some_method', expect => $some_value }) ); }

Then, we would issue a request to /tests/api/my_test

The Apache method handler C<handler> will catch it, and dispatch it.

C<my_test> calls C<_test> to perform the test, which executes the method C<some_method>, and compares the expected result against the returned value from the method call, and return an HTTP response.

If C<expect> is provided as a subroutine callback, it will be called and passed the method returned value as the first argument to the callback. For example, consider the example below:

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

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a package for testing the L<Module::Generic> module under Apache2/modperl2

=head1 TESTS

The following tests are performed:

=head2 non_threaded_error

=head2 threaded_error

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic>, L<Apache::Test>, L<Apache::TestUtil>, L<Apache::TestRequest>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
