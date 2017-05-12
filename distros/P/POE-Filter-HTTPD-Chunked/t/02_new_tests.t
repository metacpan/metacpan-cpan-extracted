#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use constant MODULE => 'POE::Filter::HTTPD::Chunked';

BEGIN {
    foreach my $req ( qw( HTTP::Request HTTP::Request::Common HTTP::Status ) ) {
        eval "use $req";
        if ( $@ ) {
            plan skip_all => "$req is needed for these tests.";
        }
    }
}

BEGIN {
    plan tests => 147;
}

use_ok( MODULE );

{ # simple get {{{
    my $filter = MODULE->new();
    isa_ok($filter, MODULE );

    my $get_request =
      HTTP::Request->new('GET', 'http://localhost/pie.mhtml');

    my $records = $filter->get([ $get_request->as_string ]);
    is(ref($records), 'ARRAY', 'simple get: get() returns list of requests');
    is(scalar(@$records), 1, 'simple get: get() returned single request');

    my $req = $records->[ 0 ];
    isa_ok(
        $req,
        'HTTP::Request',
        'simple get'
    );

    check_fields( $req, {
            method  => $get_request->method,
            url     => $get_request->url,
            content => $get_request->content,
        }, 'simple_get'
    );
} # }}}

{ # More complex get {{{
    my $filter = MODULE->new();

    my $get_data = q|GET /foo.html HTTP/1.0
User-Agent: Wget/1.8.2
Host: localhost:8080
Accept: */*
Connection: Keep-Alive

|;

    my $data = $filter->get([ $get_data ]);
    is(ref $data, 'ARRAY', 'HTTP 1.0 get: get() returns list of requests');
    is(scalar @$data, 1, 'HTTP 1.0 get: get() returned single request');

    my ($req) = @$data;

    isa_ok($req, 'HTTP::Request', 'HTTP 1.0 get');
    check_fields(
        $req,
        {
            method          => 'GET',
            url             => '/foo.html',
            content         => '',
            'User-Agent'    => 'Wget/1.8.2',
            'Host'          => 'localhost:8080',
            'Accept'        => '*/*',
            'Connection'    => 'Keep-Alive',
        },
        "HTTP 1.0 get"
    );
} # }}}

{ # simple post {{{
    my $post_request = POST 'http://localhost/foo.mhtml', [ 'I' => 'like', 'tasty' => 'pie' ];
    $post_request->protocol('HTTP/1.0');

    my $filter = MODULE->new();

    my $data = $filter->get([ $post_request->as_string ]);
    is(ref $data, 'ARRAY', 'simple post: get() returns list of requests');
    is(scalar @$data, 1, 'simple post: get() returned single request');

    my ($req) = @$data;

    isa_ok($req, 'HTTP::Request',
        'simple post: get() returns HTTP::Request object');

    check_fields($req, {
        method => 'POST',
        url => 'http://localhost/foo.mhtml',
        protocol => 'HTTP/1.0',
      }, "simple post");

    # The HTTP::Request bundled with ActivePerl 5.6.1 causes a test
    # failure here.  The one included in ActivePerl 5.8.3 works fine.
    # It was suggested by an anonymous bug reporter to test against
    # HTTP::Request's version rather than Perl's, so we're doing that
    # here.  Theoretically we shouldn't get this far.  The Makefile
    # magic should strongly suggest HTTP::Request 1.34.  But people
    # install (or fail to) the darnedest things, so I thought it was
    # safe to check here rather than fail the test due to operator
    # error.
    SKIP: {
      my $required_http_request_version = 1.34;
      skip("simple post: Please upgrade HTTP::Request to $required_http_request_version or later", 1)
        if $^O eq "MSWin32" and $HTTP::Request::VERSION < $required_http_request_version;

      is($req->content, "I=like&tasty=pie",
        'simple post: HTTP::Request object contains proper content');

      is( length($req->content), $req->header('Content-Length'),
        'simple post: Content is the right length');
    }

    is($req->header('Content-Type'), 'application/x-www-form-urlencoded',
        'simple post: HTTP::Request object contains proper Content-Type header');
} # }}}

{ # simple head {{{
    my $head_request = HEAD 'http://localhost/foo.mhtml';

    my $filter = MODULE->new();

    my $data = $filter->get([ $head_request->as_string ]);
    is(ref $data, 'ARRAY', 'simple head: get() returns list of requests');
    is(scalar @$data, 1, 'simple head: get() returned single request');

    my ( $req ) = @$data;

    isa_ok( $req, 'HTTP::Request',
        'simple head: get() returns HTTP::Request object' );

    check_fields( $req, {
            method  => $head_request->method,
            url     => $head_request->url,
        }, "simple head"
    );
} # }}}

{ # simple put {{{

    my $put_request = PUT 'http://localhost/foo.mhtml';

    my $filter = MODULE->new();

    my $data = $filter->get([ $put_request->as_string ]);
    is(ref $data, 'ARRAY', 'simple put: get() returns list of requests');
    is(scalar @$data, 1, 'simple put: get() returned single request');

    my ($req) = @$data;

    isa_ok($req, 'HTTP::Request',
        'simple put: get() returns HTTP::Request object');

    check_fields($req, {
        method => 'PUT',
        url => 'http://localhost/foo.mhtml',
      }, "simple put");
} # }}}

{ # multipart form data post {{{
    my $request = POST 'http://localhost/foo.mhtml', Content_Type => 'form-data',
                    content => [ 'I' => 'like', 'tasty' => 'pie',
                                 file => [ $0 ]
                               ];
    $request->protocol('HTTP/1.0');

    my $filter = MODULE->new();

    my $data = $filter->get([ $request->as_string ]);
    is(ref $data, 'ARRAY', 'multipart form data: get() returns list of requests');
    is(scalar @$data, 1, 'multipart form data: get() returned single request');

    my ($req) = @$data;

    isa_ok($req, 'HTTP::Request',
        'multipart form data: get() returns HTTP::Request object');

    check_fields($req, {
        method => 'POST',
        url => 'http://localhost/foo.mhtml',
        protocol => 'HTTP/1.0',
        content => $request->content,
      }, "multipart form data");

    ok($req->header('Content-Type') =~ m{multipart/form-data},
        "multipart form data: HTTP::Request object contains proper Content-Type header");
} # }}}

{ # options request {{{
    my $request = HTTP::Request->new('OPTIONS', '*');
    $request->protocol('HTTP/1.0');

    my $filter = MODULE->new();

    my $data = $filter->get([ $request->as_string ]);
    is(ref $data, 'ARRAY', 'options: get() returns list of requests');
    is(scalar @$data, 1, 'options: get() returned single request');

    my ($req) = @$data;

    isa_ok($req, 'HTTP::Request',
        'options: get() returns HTTP::Request object');

    check_fields($req, {
        method => 'OPTIONS',
        url => '*',
        protocol => 'HTTP/1.0',
      }, 'options');
} # }}}

{ # reconstruction from lots of fragments {{{
  my $req = POST 'http://localhost:1234/foobar.html',
      [ 'I' => 'like', 'honey' => 'with peas' ];
  $req->protocol('HTTP/1.1');
  my @req_frags = $req->as_string() =~ m/(..)/sg;
  my $filter = MODULE->new;

  #my $pending_ok = 0;
  my $req_too_early;
  my @records;
  while (@req_frags) {
    my $data = $filter->get([ splice(@req_frags, 0, 2) ]);
    #$pending_ok++ if $filter->get_pending();
    if (@req_frags) {
      $req_too_early++ if @$data;
    }
    push @records, @$data;
  }

  #ok($pending_ok, 'fragments: get_pending() non-empty at some point');
  #is($filter->get_pending(), undef, 'fragments: get_pending() empty at end');
  ok(!$req_too_early, "fragments: get() returning nothing until end");

  is(scalar(@records), 1, 'fragments: only one request returned');
  isa_ok($records[0], 'HTTP::Request', 'fragments: request isa HTTP::Request');
  check_fields($req, {
      method => 'POST',
      url => 'http://localhost:1234/foobar.html',
      content => $req->content,
    }, 'fragments');

} # }}}

{ # trailing content on request {{{
  my $req = HTTP::Request->new('GET', 'http://localhost:1234/foobar.html');
  $req->protocol( "HTTP/1.0" );

  # request + trailing whitespace in one block == just request
  {
    my $filter = MODULE->new;
    my $data = $filter->get([ $req->as_string . "\r\n  \r\n\n" ]);
    is(ref($data), 'ARRAY', 'trailing: whitespace in block: ref');
    is(scalar(@$data), 1, 'trailing: whitespace in block: one req');
    isa_ok($$data[0], 'HTTP::Request',
      'trailing: whitespace in block: HTTP::Request');
    check_fields($req, {
        method => 'GET',
        url => 'http://localhost:1234/foobar.html'
      }, 'trailing: whitespace in block');
  }

  # request + garbage together == request
  {
    my $filter = MODULE->new;
    my $data = $filter->get([ $req->as_string . "GARBAGE!" ]);
    is(ref($data), 'ARRAY', 'trailing: garbage in block: ref');
    is(scalar(@$data), 1, 'trailing: garbage in block: one req');
    isa_ok($$data[0], 'HTTP::Request',
      'trailing: garbage in block: HTTP::Request');
    check_fields($req, {
        method => 'GET',
        url => 'http://localhost:1234/foobar.html'
      }, 'trailing: garbage in block');
  }

  # request + trailing whitespace in separate block == just request
  {
    my $filter = MODULE->new;
    my $data = $filter->get([ $req->as_string, "\r\n  \r\n\n" ]);
    is(ref($data), 'ARRAY', 'trailing: extra whitespace packet: ref');
    is(scalar(@$data), 1, 'trailing: extra whitespace packet: one req');
    isa_ok($$data[0], 'HTTP::Request',
      'trailing: extra whitespace packet: HTTP::Request');
    check_fields($req, {
        method => 'GET',
        url => 'http://localhost:1234/foobar.html'
      }, 'trailing: extra whitespace packet');
  }

  # request + trailing whitespace in separate get == just request
  {
    my $filter = MODULE->new;
    $filter->get([ $req->as_string ]); # assume this one is fine
    my $data = $filter->get([ "\r\n  \r\n\n" ]);
    is(ref($data), 'ARRAY', 'trailing: extra whitespace get: ref');
    is(scalar(@$data), 1, 'trailing: extra whitespace get: no req');
  }

  # request + garbage in separate get == error
  # request + garbage in separate get == more data required
  {
    my $filter = MODULE->new;
    $filter->get([ $req->as_string ]); # assume this one is fine
    my $data = $filter->get([ $req->as_string, "GARBAGE!" ]);
    my $data2 = $filter->get( [ " /\n\n" ] );

    check_error_response( $data2, RC_BAD_REQUEST, 'garbage request line: bad request' );
  }
} # }}}

TODO: { # wishlist for supporting get_pending! {{{
    local $TODO = 'add get_pending support';
    my $filter = MODULE->new;
    eval { $filter->get_pending() };
    ok($@, 'get_pending not supported!');
} # }}}

{ # basic checkout of put {{{
    my $res = HTTP::Response->new("404", "Not found");

    my $filter = MODULE->new;

    use Carp;
    $SIG{__DIE__} = \&Carp::croak;
    my $chunks = $filter->put([$res]);
    is(ref($chunks), 'ARRAY', 'put: returns arrayref');
} # }}}

{ # really, really garbage requests get rejected, but goofy ones accepted {{{
    {
        my $filter = MODULE->new;
        my $data = $filter->get([ "ELEPHANT\n\r\n" ]);

        check_error_response($data, RC_BAD_REQUEST,
            'garbage request line: bad request'
        );
    }

    {
        my $filter = MODULE->new;
        my $data = $filter->get([ "GET\t/elephant.gif HTTP/1.0\n\n" ]);
        isa_ok( $data->[0], 'HTTP::Request', 'goofy request accepted');
        check_fields(
            $data->[0],
            {
                protocol => 'HTTP/1.0',
                method => 'GET',
                uri => '/elephant.gif',
            },
            'goofy request'
        );
    }
} # }}}

{ # strange method {{{
    my $filter = MODULE->new;
    my $req = HTTP::Request->new("GEt", "/");
    $req->protocol( 'HTTP/1.0' );

    my $parsed_req = $filter->get([ $req->as_string ])->[0];
    check_fields(
        $parsed_req,
        {
            protocol => 'HTTP/1.0',
            method => 'GEt',
            uri => '/',
        },
        "mixed case method"
    );
} # }}}

### Chunking tests
#
{ # chunked request
    my $filter = MODULE->new;

    my $req1 = HTTP::Request->new( 'POST', '/' );
    $req1->protocol( "HTTP/1.1" );
    $req1->header( 'transfer-encoding' => 'chunked' );
    $req1->content( _make_chunks( content => 'x' x 1000, chunk_size => 100, trailers => { a => 100, b => 102 } ) );

    my $req2 = HTTP::Request->new( 'POST', '/blahblah' );
    $req2->protocol( "HTTP/1.1" );
    $req2->header( 'transfer-encoding' => 'chunked' );
    $req2->content( _make_chunks( chunk_size => 23, content => 'y' x 100 ) );

    my $data = $filter->get( [ $req1->as_string, $req2->as_string ] );
    my $data2 = $filter->get( [] );
    my $data3 = $filter->get( [] );

    is( ref( $data ), 'ARRAY', 'multiple chunked request: first get: ref' );
    is( scalar( @$data ), 1, 'multiple chunked request: first get: one req' );
    isa_ok( $data->[ 0 ], 'HTTP::Request', 'multiple chunked request: first get: is HTTP::Request' );
    check_fields(
        $data->[ 0 ],
        {
            method          => 'POST',
            uri             => '/',
            protocol        => 'HTTP/1.1',
            content_length  => 1000,
            content         => 'x' x 1000,
            a               => 100,
            b               => 102,
        },
        'multiple chunked request: first object'
    );

    is( ref( $data2 ), 'ARRAY', 'multiple chunked request: second get: ref' );
    is( scalar( @$data2 ), 1, 'multiple chunked request: second get: one req' );
    isa_ok( $data2->[ 0 ], 'HTTP::Request', 'multiple chunked request: second get: is HTTP::Request' );
    check_fields(
        $data2->[ 0 ],
        {
            method          => 'POST',
            uri             => '/blahblah',
            protocol        => 'HTTP/1.1',
            content_length  => 100,
            content         => 'y' x 100,
        },
        'multiple chunked request: second object'
    );

    is( ref( $data3 ), 'ARRAY', 'multiple chunked request: third get: ref' );
    is( scalar( @$data3 ), 0, 'multiple chunked request: third get: no req' );
}

{ # multiple transfer-encodings, ensure handling chunked properly
    my $filter = MODULE->new;

    my $content = 'x' x 1000;

    my $req1 = HTTP::Request->new( 'POST', '/' );
    $req1->protocol( "HTTP/1.1" );
    $req1->header( 'transfer-encoding' => 'gzip, chunked' );
    $req1->content( _make_chunks( content => $content, chunk_size => 100 ) );

    my $data = $filter->get( [ $req1->as_string ] );

    is( ref( $data ), 'ARRAY', 'multiple transfer encodings: ref' );
    is( scalar( @$data ), 1, 'multiple transfer encodings: one req' );
    isa_ok( $data->[ 0 ], 'HTTP::Request', 'multiple transfer encodings: is HTTP::Request' );
    check_fields(
        $data->[ 0 ],
        {
            method              => 'POST',
            uri                 => '/',
            protocol            => 'HTTP/1.1',
            content_length      => length $content,
            content             => $content,
            'transfer-encoding' => 'gzip',
        },
        'multiple transfer encodings: object compare'
    );
}

{ # chunked errors - wrong proto
    my $filter = MODULE->new;

    my $req = HTTP::Request->new( 'POST', '/' );
    $req->protocol( 'HTTP/1.0' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content( _make_chunks() );

    my $data = $filter->get( [ $req->as_string ] );
    
    is( ref( $data ), 'ARRAY', 'chunked with wrong proto: ref' );
    is( scalar( @$data ), 1, 'chunked with wrong proto: one req' );
    isa_ok( $data->[ 0 ], 'HTTP::Response', 'chunked with wrong proto: is HTTP::Response' );
}

{ # chunked errors - conflicting headers
    my $filter = MODULE->new;

    my $req = HTTP::Request->new( 'POST', '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content_length( 1 );
    $req->content( _make_chunks() );

    my $data = $filter->get( [ $req->as_string ] );

    is( ref( $data ), 'ARRAY', 'chunked with conflicting headers: ref' );
    is( scalar( @$data ), 1, 'chunked with conflicting headers: one req' );
    isa_ok( $data->[ 0 ], 'HTTP::Response', 'chunked with conflicting headers: is HTTP::Response' );
}

{ # chunked errors - bad trailers
    my $filter = MODULE->new;

    my $req = HTTP::Request->new( 'POST', '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content( _make_chunks( trailers => { 'content-length' => 32 } ) );

    my $data = $filter->get( [ $req->as_string ] );

    is( ref( $data ), 'ARRAY', 'chunked with invalid trailers: ref' );
    is( scalar( @$data ), 1, 'chunked with invalid trailers: one req' );
    isa_ok( $data->[ 0 ], 'HTTP::Response', 'chunked with invalid trailers: is HTTP::Response' );
}

{ # chunked - emit on partial chunks
    my $filter = MODULE->new( event_on_chunk => 1 );

    my $req = HTTP::Request->new( 'POST' => '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content( _make_chunks( chunk_size => 5, content => '12345' x 6 ) );
    $req = $req->as_string;

    my $part1 = substr( $req, 0, 80 );
    my $part2 = substr( $req, 80, 10 );
    my $part3 = substr( $req, 90 );

    my $data1 = $filter->get( [ $part1 ] );
    is( ref $data1, 'ARRAY', 'partial chunks: partial chunk read returns array' );
    is( scalar @$data1, 1, 'partial chunks: first get returns single item' );
    isa_ok( $data1->[ 0 ], 'HTTP::Request::Chunked', 'partial chunks: first get is HTTP::Request::Chunked, as only partial request' );

    my $data2 = $filter->get( [ $part2 ] );
    is( ref $data2, 'ARRAY', 'partial chunks: partial chunk read returns array' );
    is( scalar @$data2, 1, 'partial chunks: second get returns single item' );
    isa_ok( $data2->[ 0 ], 'HTTP::Request::Chunked', 'partial chunks: second get is HTTP::Request::Chunked, as only partial request' );

    my $data3 = $filter->get( [ $part3 ] );
    is( ref $data3, 'ARRAY', 'partial chunks: partial chunk read returns array' );
    is( scalar @$data3, 1, 'partial chunks: second get returns single item' );
    isa_ok( $data3->[ 0 ], 'HTTP::Request', 'partial chunks: second get is HTTP::Request, as now have complete request' );

    my $data4 = $filter->get( [ $req ] );
    is_deeply( $data3, $data4, 'partial chunks: full request after partial ones are identical' );
}

{ # chunked - invalid chunk size
    my $filter = MODULE->new;

    my $invalid_data = <<EOINVALID;
5
12345
5
12345
qqqq
aaaaaaaaaaaaaaaaaaaaaa
EOINVALID

    my $req = HTTP::Request->new( 'POST' => '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content( $invalid_data );
    $req = $req->as_string;

    my $data = $filter->get( [ $req ] );
    is( ref $data, 'ARRAY', 'invalid chunk size: get returns array' );
    is( scalar @$data, 1, 'invalid chunk size: get returns single item' );
    isa_ok( $data->[ 0 ], 'HTTP::Response', 'invalid chunk size: get returns HTTP::Response' );
}

{ # chunked - with chunk comment
    my $filter = MODULE->new;

    my $req = HTTP::Request->new( 'POST' => '/' );
    $req->protocol( 'HTTP/1.1' );
    $req->header( 'transfer-encoding' => 'chunked' );
    $req->content( _make_chunks( chunk_size => 5, content => '12345' x 6, with_comment => 1 ) );
    $req = $req->as_string;

    my $data = $filter->get( [ $req ] );
    is( ref $data, 'ARRAY', 'chunk with comment: get returns array' );
    is( scalar @$data, 1, 'chunk with comment: get returns single item' );
    isa_ok( $data->[ 0 ], 'HTTP::Request', 'chunk with comment: get returns HTTP::Request' );
}

{ # clone
    my $filter = MODULE->new;

    my $method = 'POST';
    my $uri = '/';
    my $protocol = 'HTTP/1.1';
    my $content = 'request';
    my $headers = [
        'content-length'    => length $content
    ];

    my $request = HTTP::Request->new( $method, $uri, $headers, $content );
    $request->protocol( $protocol );

    my $request_str = $request->as_string;

    # don't pass full request to get, so we have some data in the buffer.
    $filter->get( [ substr( $request_str, 0, length( $request_str ) - 5 ) ] );

    my $clone = $filter->clone;

    isa_ok( $clone, MODULE, 'clone: expected class' );

    # if clone is valid, we should be able to pass in a new request, and not have it
    # choke, due to having copied buffer, or preserving other detail
    my $data = $clone->get( [ $request_str ] );
    is( ref( $data ), 'ARRAY', 'clone: ref' );
    isa_ok( $data->[ 0 ], 'HTTP::Request', 'clone: get returns expected class' );
    check_fields(
        $data->[ 0 ],
        {
            method          => $method,
            uri             => $uri,
            protocol        => $protocol,
            content         => $content,
            @{ $headers },
        },
        'clone: object compare'
    );
}

sub _make_chunks {
    my %args = @_;

    my ( $content, $size, $trailers, $comment ) = @args{ qw( content chunk_size trailers with_comment ) };

    $content = 'x' x 1000 if not defined $content;
    $size = 99 if not defined $size;
    $trailers = {} if not defined $trailers;

    use bytes;

    my $out = '';
    while ( my $current = substr( $content, 0, $size, '' ) ) {
        if ( $comment ) {
            $out .= sprintf( "%x; this is a comment\r\n%s\r\n", length $current, $current );
        } else {
            $out .= sprintf( "%x\r\n%s\r\n", length $current, $current );
        }
    }

    $out .= sprintf( "%x\r\n", 0 );

    # append any trailers to the request.
    foreach my $trailer ( keys %{ $trailers } ) {
        $out .= sprintf( "%s: %s\r\n", $trailer, $trailers->{ $trailer } );
    }

    # and end with a final CRLF
    $out .= "\r\n";

    return $out;
}

# takes a object, and a hash { method_name => expected_value },
# and an optional name for the test
# uses is(), so values are simple scalars
sub check_fields {
    my ($object, $expected, $name) = @_;

    $name = $name ? "$name: " : "";

    while ( my ( $method, $expected_value ) = each %$expected) {
        my $to_compare = $object->can( $method )
          ? $object->$method
          : $object->header( $method );

        is( $to_compare, $expected_value, "$name$method" );
    }
}

sub check_error_response {
    my ($data, $code, $label) = @_;

    ok(
        (ref($data) eq 'ARRAY') &&
        (scalar(@$data) == 1) &&
        ($$data[0]->code == $code),
        $label
    );
}

