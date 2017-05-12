# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mock-LWP-Request.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Status    qw( :constants );

#use Test::More tests => 8;
use Test::More;
use Test::Exception;

BEGIN { use_ok('Mock::LWP::Request') };

my $mocked_lwp = Mock::LWP::Request->new();
isa_ok( $mocked_lwp, "Mock::LWP::Request");

is_deeply( $mocked_lwp->old_lwp_request, \&LWP::UserAgent::request,
    'old_lwp_request is correct');

my $ua = LWP::UserAgent->new( timeout => 1 );
my $response = $ua->get('http://www.example.com/');

ok( $response, "I have some kind of response");

$mocked_lwp->enable;
dies_ok( sub { $ua->get('http://www.example.com/') },
    "Call to request() dies if no response is available" );

$mocked_lwp->missing_response_action('default');
lives_ok( sub { $response = $ua->get('http://www.example.com.au/') },
    "Call to request() lives if no response available but missing_response_action is 'default'" );

is( $response->code, HTTP_PRECONDITION_FAILED, "Response status is correct" );

$mocked_lwp->missing_response_action('die');
$mocked_lwp->add_response( HTTP::Response->new( HTTP_NO_CONTENT ) );

$response = $ua->get('http://www.example.com.au/');
ok( $response, "I have a response" );
isa_ok( $response, "HTTP::Response" );
is( $response->code, HTTP_NO_CONTENT, "Correct response returned" );

my @responses = (
    {
        code    => HTTP_OK,
        message => 'OK',
    },
    {
        code    => HTTP_I_AM_A_TEAPOT,
    },
    {
        code    => HTTP_INTERNAL_SERVER_ERROR,
    },
);

foreach my $r (@responses) {
    $mocked_lwp->add_response( HTTP::Response->new( $r->{code}, $r->{message} // undef ) );
}

foreach my $r (@responses) {
    my $response = $ua->get('http://www.example.com.au/');
    ok( $response, "I have a response" );
    isa_ok( $response, "HTTP::Response" );
    is( $response->code, $r->{code}, "Correct response returned" );
}

done_testing;
