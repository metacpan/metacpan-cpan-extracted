use strict;
use warnings;
use Test::More;
use Test::LongString;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $log;
my $handler = builder {
    enable 'Plack::Middleware::DebugLogging',
        logger => sub { $log .= $_[0]->{message}."" }, term_width => 80;
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
};

my $test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $log = '';
    $test_req->(GET "http://localhost/");
    is $log, <<LOG
"GET" request for "/" from "127.0.0.1"
Request Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Host            | localhost                                            |
| Content-Length  | 0                                                    |
'-----------------+------------------------------------------------------'

Response Code: 200; Content-Type: text/plain; Content-Length: unknown
Response Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Content-Type    | text/plain                                           |
'-----------------+------------------------------------------------------'

LOG
, 'simple request works.';
}

{
    $log = '';
    $test_req->(POST "http://localhost/?a=b&c=d&a=e", [ foo => 'bar' , baz => 'beep' ]);
    is $log, <<LOG
"POST" request for "/" from "127.0.0.1"
Request Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Host            | localhost                                            |
| Content-Length  | 16                                                   |
| Content-Type    | application/x-www-form-urlencoded                    |
'-----------------+------------------------------------------------------'

Query Parameters are:
.-------------------------------------+--------------------------------------.
| Parameter                           | Value                                |
+-------------------------------------+--------------------------------------+
| a                                   | b, e                                 |
| c                                   | d                                    |
'-------------------------------------+--------------------------------------'

Body Parameters are:
.-------------------------------------+--------------------------------------.
| Parameter                           | Value                                |
+-------------------------------------+--------------------------------------+
| baz                                 | beep                                 |
| foo                                 | bar                                  |
'-------------------------------------+--------------------------------------'

Response Code: 200; Content-Type: text/plain; Content-Length: unknown
Response Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Content-Type    | text/plain                                           |
'-----------------+------------------------------------------------------'

LOG
, 'combinations of body and query params work.';
}

{
    $log = '';
    $test_req->(POST "http://localhost", Content_Type => 'application/json', Content => '{"a": 5 }');
is_string $log, <<LOG
"POST" request for "/" from "127.0.0.1"
Request Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Host            | localhost                                            |
| Content-Length  | 9                                                    |
| Content-Type    | application/json                                     |
'-----------------+------------------------------------------------------'

application/json encoded body parameters are:
{
  a => 5
}

Response Code: 200; Content-Type: text/plain; Content-Length: unknown
Response Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Content-Type    | text/plain                                           |
'-----------------+------------------------------------------------------'

LOG
, 'json body with content-type set deserialized properly'};
# Testing streaming responses

$log = "";
$handler = builder {
    enable 'Plack::Middleware::DebugLogging',
        logger => sub { $log .= $_[0]->{message}."" }, term_width => 80;
    sub {
        return sub {
            my $writer = $_[0]->( [ 200, [ 'Content-Type' => 'text/plain' ] ] );
            $writer->write("OK");
            $writer->close;
        }
    };
};

$test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $test_req->(GET "http://localhost/?keyword+bar");
    is $log, <<LOG
"GET" request for "/" from "127.0.0.1"
Request Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Host            | localhost                                            |
| Content-Length  | 0                                                    |
'-----------------+------------------------------------------------------'

Query keywords are: keyword bar

Query Parameters are:
.-------------------------------------+--------------------------------------.
| Parameter                           | Value                                |
+-------------------------------------+--------------------------------------+
| keyword bar                         |                                      |
'-------------------------------------+--------------------------------------'

Response Code: 200; Content-Type: text/plain; Content-Length: unknown
Response Headers:
.-----------------+------------------------------------------------------.
| Header Name     | Value                                                |
+-----------------+------------------------------------------------------+
| Content-Type    | text/plain                                           |
'-----------------+------------------------------------------------------'

LOG
, 'keywords and streaming responses work.'}

done_testing;
