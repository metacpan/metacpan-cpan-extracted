#!perl 
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp();
use Net::ICAP::Client();
use HTTP::Headers();
use IO::Socket::INET();

my $number_of_tests = 118;
plan tests => $number_of_tests;

my $uri = 'icap://localhost/av';

MAIN: {
    my $test_host_name      = 'something.example.com';
    my $test_directory_name = 'foo';
    my $test_file_name      = 'bar';
    my $icap                = Net::ICAP::Client->new(
        'icaps://ssl-proxy.example.com',
        SSL_ca_file => '/path/to/ca-bundle.crt'
    );
    $icap = Net::ICAP::Client->new($uri);
    ok( $icap, "Initialised icap object" );
    ok( $icap->uri() eq $uri,
        "URI is retrieved from \$icap->uri() - " . $icap->uri() );
    my $socket = IO::Socket::INET->new(
        PeerAddr => $icap->uri()->host(),
        PeerPort => $icap->uri()->port(),
        Proto    => 'tcp',
    );
    my $original_agent =
      $icap->agent( $icap->agent() . " - exercising test suite" );
    ok( $original_agent, "\$icap->agent() is '$original_agent'" );
    ok( $icap->agent() =~ /exercising[ ]test[ ]suite/smx,
        "\$icap->agent() has been updated to '" . $icap->agent() . "'" );
    ok( $icap->allow_204(0),
        "\$icap->allow_204() defaults to true but has been turned off" );
    ok( $icap->allow_preview(0),
        "\$icap->allow_preview() defaults to true but has been turned off" );
    ok( !$icap->debug(1), "Setting debug on" );
  SKIP: {

        if ( !$socket ) {
            diag("No icap server available at $uri");
            skip(
                "ICAP Server at "
                  . $icap->uri()
                  . " is unavailable for testing",
                1
            );
        }
        ok( $icap->service(), "\$icap->service() is " . $icap->service() );
        diag( "Service is '" . $icap->service() . "'" );
    }
  SKIP: {
        skip( "ICAP Server at " . $icap->uri() . " is unavailable for testing",
            $number_of_tests - 8 )
          if ( !$socket );
        ok( $icap->server_allows_204(),
            "\$icap->server_allows_204() is at " . $icap->server_allows_204() );
        ok( $icap->is_tag(), "\$icap->is_tag() is at " . $icap->is_tag() );
        ok( $icap->ttl(), "\$icap->ttl() is " . $icap->ttl() );
        ok( $icap->preview_size(),
            "\$icap->preview_size() is " . $icap->preview_size() );
        my $request_headers = HTTP::Headers->new();
        $request_headers->push_header( 'Content-Type',
            'application/octet-stream' );
        my $virus_handle = File::Temp::tempfile()
          or Carp::croak "Failed to open temporary file:$!";
        $virus_handle->print(
"X5O!P\%\@AP[4\\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*"
        ) or Carp::croak "Failed to write to temporary file:$!";
        $virus_handle->seek( 0, 0 )
          or Carp::croak "Failed to seek to start of temporary file:$!";
        my $request =
          HTTP::Request->new( 'POST',
            "https://$test_host_name/$test_directory_name/$test_file_name",
            $request_headers );
        my ( $new_handle, $old_handle ) = open_stderr();
        my ( $headers, $body );
        eval {
            ( $headers, $body ) = $icap->request( $request, $virus_handle );
        };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->request() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Response'),
"McAfee server returned a response to a separate POST request body containing the EICAR string"
        );
        ok(
            $headers && $headers->code() == 403,
            "McAfee server response has a status code of 403 ("
              . ( defined $headers ? $headers->code() : q[] ) . ")"
        );
        ok(
            $headers && $headers->header('Content-Type') eq 'text/html',
            "McAfee server response has a Content-Type of 'text/html' ('"
              . ( defined $headers ? $headers->header('Content-Type') : q[] )
              . "')"
        );
        my $good_handle = File::Temp::tempfile()
          or Carp::croak "Failed to open temporary file:$!";
        $good_handle->print(
            "Weird data ***********!#^*()[]{}':;<>,.?/" . ( 'x' x 500 ) )
          or Carp::croak "Failed to write to temporary file:$!";
        $good_handle->seek( 0, 0 )
          or Carp::croak "Failed to seek to start of temporary file:$!";
        $request_headers->push_header( 'Accept-Encoding', 'gzip' );
        $request =
          HTTP::Request->new( 'POST',
            "https://$test_host_name/$test_directory_name/$test_file_name",
            $request_headers );
        ( $new_handle, $old_handle ) = open_stderr();
        eval { ( $headers, $body ) = $icap->request( $request, $good_handle ); };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->request() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Request'),
"McAfee server returned a request for a separate POST request body containing data that is not a virus"
        );
        $request =
          HTTP::Request->new( 'POST',
            "https://$test_host_name/$test_directory_name/$test_file_name",
            $request_headers, "What is going on here?" );
        ( $new_handle, $old_handle ) = open_stderr();
        eval { ( $headers, $body ) = $icap->request($request); };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->request() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Request'),
"McAfee server returned a request for an integrated POST request body containing data that is not a virus"
        );
        $icap->debug(0);
        ok( !$icap->allow_204(1), "\$icap->allow_204() has been turned on" );
        ok( !$icap->allow_preview(1),
            "\$icap->allow_preview() has been turned on" );
        my $preview_ok = 1;
        my $start = $icap->preview_size() > 20 ? $icap->preview_size() - 20 : 1;

        foreach my $file_size ( $start .. ( $icap->preview_size() + 20 ) ) {
            $request = HTTP::Request->new(
                'POST',
                "https://$test_host_name/$test_directory_name/$test_file_name",
                $request_headers,
                "X" x $file_size
            );
            eval { ( $headers, $body ) = $icap->request($request); };
            ok( !$@, "\$icap->request() did not throw an exception:$@" );
            if ( $headers && $headers->isa('HTTP::Request') ) {
            }
            else {
                $preview_ok = 0;
            }
        }
        $icap->debug(1);
        ok( $preview_ok,
            "Data across the preview range for requests is handled correctly" );
        $request =
          HTTP::Request->new( 'GET',
            "https://$test_host_name/$test_directory_name/$test_file_name",
          );
        ( $new_handle, $old_handle ) = open_stderr();
        eval { ( $headers, $body ) = $icap->request($request); };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->request() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Request'),
            "McAfee server returned a request for an GET request without a body"
        );
        $request =
          HTTP::Request->new( 'GET',
            "https://$test_host_name/$test_directory_name/$test_file_name",
          );
        my $response_headers = HTTP::Headers->new();
        $response_headers->push_header( 'Content-Type',
            'application/octet-stream' );
        my $response =
          HTTP::Response->new( '200', 'OK', $response_headers, "Short Stuff" );
        ( $new_handle, $old_handle ) = open_stderr();
        eval { ( $headers, $body ) = $icap->response( $request, $response ); };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->response() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Response'),
"McAfee server returned a response for an GET request and a response with an inline body"
        );
        $good_handle->seek( 0, 0 )
          or Carp::croak "Failed to seek to start of temporary file:$!";
        $request =
          HTTP::Request->new( 'POST',
            "https://$test_host_name/$test_directory_name/$test_file_name",
            $request_headers, "What is going on here?" );
        $response =
          HTTP::Response->new( '200', 'OK', $response_headers, $good_handle );
        ( $new_handle, $old_handle ) = open_stderr();
        eval {
            ( $headers, $body ) =
              $icap->response( $request, $response, $good_handle );
        };
        check_stderr( $new_handle, $old_handle );
        ok( !$@, "\$icap->response() did not throw an exception:$@" );
        ok(
            $headers && $headers->isa('HTTP::Response'),
"McAfee server returned a response for a POST request and a response with an external body"
        );
        $icap->debug(0);
        $preview_ok = 1;

        foreach my $file_size ( $start .. ( $icap->preview_size() + 20 ) ) {
            $response = HTTP::Response->new( '200', 'OK', $response_headers,
                "X" x $file_size );
            eval {
                ( $headers, $body ) = $icap->response( $request, $response );
            };
            ok( !$@, "\$icap->response() did not throw an exception:$@" );
            if ( $headers && $headers->isa('HTTP::Response') ) {
            }
            else {
                $preview_ok = 0;
            }
        }
        $icap->debug(1);
        ok( $preview_ok,
            "Data across the preview range for responses is handled correctly"
        );
    }
}

sub open_stderr {
    my $old = select STDERR;
    $| = 1;
    select $old;
    my $new_handle = File::Temp::tempfile()
      or Carp::croak("Failed to open temporary file:$!");
    my $old_handle = File::Temp::tempfile()
      or Carp::croak("Failed to open temporary file:$!");
    open( $old_handle, ">&STDERR" )
      or Carp::croak("Failed to redirect STDERR:$!");
    $old = select $old_handle;
    $|   = 1;
    select $old;
    open( STDERR, ">&=", $new_handle )
      or Carp::croak("Failed to redirect STDERR:$!");
    $old = select $new_handle;
    $|   = 1;
    select $old;
    $old = select STDERR;
    $|   = 1;
    select $old;
    return ( $new_handle, $old_handle );
}

sub check_stderr {
    my ( $new_handle, $old_handle ) = @_;
    seek $new_handle, 0, 0
      or Carp::croak("Failed to seek to start of temporary file:$!");
    open( STDERR, ">&=", $old_handle )
      or Carp::croak("Failed to redirect STDERR:$!");
    my $prefixes_ok = 1;
    while ( my $line = <$new_handle> ) {
        diag($line);
        if ( $line !~ /^(<<|>>)[ ]/smx ) {
            $prefixes_ok = 0;
        }
    }
    ok( $prefixes_ok,
        "Debug output is correctly prefixed with '>> ' or '<< '" );
    return 1;
}
