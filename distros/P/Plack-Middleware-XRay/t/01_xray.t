use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::XRay;
use HTTP::Request::Common;
use AWS::XRay qw/ capture /;
use t::Util qw/ reset segments /;

my $app = sub {
    my $env = shift;
    capture "myApp", sub {
        [200, ['Content-Type' => 'text/plain'], ["Hello World\n"]];
    };
};
$app = Plack::Builder::builder {
    enable "XRay",
        name => "myTest",
        annotations => {
            foo => "bar",
        },
        metadata => {
            bar => "baz",
        },
        annotations_builder => sub {
            my $e = shift;
            +{ user_id => $e->{HTTP_X_USER_ID} }
        },
        metadata_builder => sub {
            my $e = shift;
            +{ app_id => $e->{HTTP_X_APP_ID} }
        };
    $app;
};

test_psgi $app, sub {
    reset;
    my $cb = shift;
    my $res = $cb->(
        GET '/foo/bar',
        "X-User-ID" => "123456",
        "X-App-ID"  => "9999",
    );
    my ($segApp, $segPlack) = segments();
    is $segPlack->{name}    => "myTest";
    is $segApp->{trace_id}  => $segPlack->{trace_id};
    is $segApp->{parent_id} => $segPlack->{id};
    is $segPlack->{http}->{request}->{method}  => "GET";
    is $segPlack->{http}->{request}->{url}     => "http://localhost/foo/bar";
    is $segPlack->{http}->{response}->{status} => 200;
    is $segPlack->{annotations}->{foo}     => "bar";
    is $segPlack->{annotations}->{user_id} => "123456";
    is $segPlack->{metadata}->{bar}        => "baz";
    is $segPlack->{metadata}->{app_id}     => "9999";
};

my $trace_id   = AWS::XRay::new_trace_id();
my $segment_id = AWS::XRay::new_id();

test_psgi $app, sub {
    reset;
    my $cb = shift;
    my $res = $cb->(
        GET '/',
        "X-Amzn-Trace-ID" => "Root=$trace_id",
    );
    my ($segApp, $segPlack) = segments();
    is $segPlack->{name}     => "myTest";
    is $segPlack->{trace_id} => $trace_id;
    is $segApp->{trace_id}   => $segPlack->{trace_id};
    is $segApp->{parent_id}  => $segPlack->{id};
    is $segPlack->{http}->{request}->{method}  => "GET";
    is $segPlack->{http}->{request}->{url}     => "http://localhost/";
    is $segPlack->{http}->{response}->{status} => 200;
};

test_psgi $app, sub {
    reset;
    my $cb = shift;
    my $res = $cb->(
        GET '/',
        "X-Amzn-Trace-ID" => "Parent=$segment_id;Root=$trace_id",
    );
    my ($segApp, $segPlack) = segments();
    is $segPlack->{name}      => "myTest";
    is $segPlack->{trace_id}  => $trace_id;
    is $segPlack->{parent_id} => $segment_id;
    is $segApp->{trace_id}    => $segPlack->{trace_id};
    is $segApp->{parent_id}   => $segPlack->{id};
    is $segPlack->{http}->{request}->{method}  => "GET";
    is $segPlack->{http}->{request}->{url}     => "http://localhost/";
    is $segPlack->{http}->{response}->{status} => 200;
};

done_testing;

