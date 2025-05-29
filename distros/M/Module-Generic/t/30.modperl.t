#!/usr/local/bin/perl
BEGIN
{
    use Test::More;
    use lib './lib';
    use vars qw( $DEBUG $VERSION $hostport $host $port $mp_host $proto $ua @ua_args );
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    use constant HAS_SSL => $ENV{HAS_SSL};
    if( HAS_APACHE_TEST )
    {
        use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" );
        use_ok( 'Apache2::Const', qw( -compile :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Const" );
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        use_ok( 'HTTP::Request' ) || BAIL_OUT( "Unable to load HTTP::Request" );
        use_ok( 'JSON' ) || BAIL_OUT( "Unable to load JSON" );
        plan no_plan;
    }
    else
    {
        plan skip_all => 'Not running under modperl';
    }
    use Module::Generic::File qw( file );
    # 2021-11-1T167:12:10+0900
    use Test::Time time => 1635754330;
    use URI;
    our $DEBUG = exists( $ENV{MG_DEBUG} ) ? $ENV{MG_DEBUG} : exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    our $VERSION = 'v0.1.0';
    our( $hostport, $host, $port, $mp_host, $proto, $ua );
    require( "./t/env.pl" ) if( -e( "t/env.pl" ) );
};

BEGIN
{
    if( HAS_APACHE_TEST )
    {
        my $config = Apache::Test::config();
        $hostport = Apache::TestRequest::hostport( $config ) || '';
        ( $host, $port ) = split( ':', ( $hostport ) );
        $mp_host = 'www.example.org';
        our @ua_args = (
            agent           => 'Test-Apache2-API/' . $VERSION,
            cookie_jar      => {},
            default_headers => HTTP::Headers->new(
                Host            => "${mp_host}:${port}",
                Accept          => 'application/json; version=1.0; charset=utf-8, text/javascript, */*',
                Accept_Encoding => 'gzip, deflate, br',
                Accept_Language => 'en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2',
            ),
            keep_alive      => 1,
        );
        Apache::TestRequest::user_agent( @ua_args, reset => 1 );
        $ua = Apache::TestRequest->new( @ua_args );
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
    }
    $proto = HAS_SSL ? 'https' : 'http';
    diag( "Host: '$host', port '$port'" ) if( $DEBUG );
};

use strict;
use warnings;
our $config = Apache::TestConfig->thaw->httpd_config;
die( "No directory \"t/logs\"" ) if( !$config->{vars}->{t_logs} || !-e( $config->{vars}->{t_logs} ) );
our $logs_dir = file( $config->{vars}->{t_logs} );
our $target2path = 
{
    mg => $logs_dir->child( 'apache2/mg' ),
    # Other test classes here, if necessary...
};

subtest 'core' => sub
{
    my( $req, $resp );
    &simple_test({ target => 'mg', name => 'has_modperl', code => Apache2::Const::HTTP_OK });

    &simple_test({ target => 'mg', name => 'json', code => Apache2::Const::HTTP_OK });

    $resp = &make_request( mg => 'dummy_error' );
    my $j = JSON->new;
    my $content = $resp->decoded_content;
    diag( "test 'dummy_error' decoded_content is '$content'" ) if( $DEBUG );
    my $ref;
    eval
    {
        $ref = $j->decode( $content );
    };

    ok( ref( $ref ) eq 'HASH', 'reply -> JSON decoded content is an hash reference' );
    is( $resp->code, Apache2::Const::HTTP_BAD_REQUEST, 'response code' );
    is( $ref->{error}->{code}, 400, 'error code' );
    is( $ref->{error}->{message}, 'Oh no!', 'error message' );

    $resp = &make_request( mg => 'non_threaded_error' );
    $content = $resp->decoded_content;
    diag( "test 'non_threaded_error' decoded_content is '$content'" ) if( $DEBUG );
    eval
    {
        $ref = $j->decode( $content );
    };
    
    ok( ref( $ref ) eq 'HASH', 'non_threaded_error -> JSON decoded content is an hash reference' );
    is( $resp->code, Apache2::Const::HTTP_BAD_REQUEST, 'non_threaded_error response code' );
    is( $ref->{error}->{code}, 400, 'non_threaded_error error code' );
    is( $ref->{error}->{message}, 'Non-threaded error test', 'non_threaded_error error message' );

    SKIP:
    {
        # Threaded error test requires Worker/Event MPM; skip if Prefork
        if( $config->{mpm} !~ /^(worker|event)$/i )
        {
            skip( "Skipping threaded_error test; not running under Worker/Event MPM", 4 );
        }
        $resp = &make_request( mg => 'threaded_error' );
        $content = $resp->decoded_content;
        diag( "test 'threaded_error' decoded_content is '$content'" ) if( $DEBUG );
        eval
        {
            $ref = $j->decode( $content );
        };
        
        ok( ref( $ref ) eq 'HASH', 'threaded_error -> JSON decoded content is an hash reference' );
        is( $resp->code, Apache2::Const::HTTP_BAD_REQUEST, 'threaded_error response code' );
        is( $ref->{error}->{code}, 400, 'threaded_error error code' );
        is( $ref->{error}->{message}, 'Threaded error test', 'threaded_error error message' );
    };
};

sub make_request
{
    my( $type, $path, $opts ) = @_;

    my $http_meth = uc( $opts->{http_method} // 'GET' );
    my $req = HTTP::Request->new( $http_meth => "${proto}://${hostport}/tests/${type}/${path}",
        ( exists( $opts->{headers} ) ? $opts->{headers} : () ),
        ( ( exists( $opts->{body} ) && length( $opts->{body} // '' ) ) ? $opts->{body} : () ),
    );
    if( $opts->{query} )
    {
        my $u = URI->new( $req->uri );
        $u->query( $opts->{query} );
        $req->uri( $u );
    }

    unless( $req->header( 'Content-Type' ) )
    {
        $req->header( Content_Type => 'text/plain; charset=utf-8' );
    }

    # $req->header( Host => "${mp_host}:${port}" );
    diag( "Request for $path is: ", $req->as_string ) if( $DEBUG );
    my $resp = $ua->request( $req );
    diag( "Server response for $path is: ", $resp->as_string ) if( $DEBUG );
    return( $resp );
}

sub simple_test
{
    my $opts = shift( @_ );
    if( !$opts->{name} )
    {
        die( "No test name was provided." );
    }
    elsif( !defined( $opts->{code} ) )
    {
        die( "No HTTP code was provided." );
    }
    elsif( !defined( $opts->{target} ) )
    {
        die( "No test target was provided. It should be 'api', 'request' or 'response'" );
    }
    my $resp = &make_request( $opts->{target} => $opts->{name}, $opts );
    is( $opts->{code}, Apache2::Const::HTTP_OK, $opts->{name} ) || 
        diag( "Error with test \"$opts->{name}\". See log content below:\n", &get_log( $opts ) );
}

sub get_log
{
    my $opts = shift( @_ );
    my $log_file = $target2path->{ $opts->{target} }->child( $opts->{name} . '.log' );
    if( $log_file->exists )
    {
        return( $log_file->load_utf8 );
    }
    else
    {
        diag( "Test $opts->{target} -> $opts->{name} seems to have failed, but there is no log file \"$log_file\"" ); 
    }
}

done_testing();

__END__
