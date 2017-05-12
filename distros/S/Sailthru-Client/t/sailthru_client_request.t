use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Exception;
use Readonly;
use HTTP::Response;
use URI;

use lib 'lib';
use Sailthru::Client;

Readonly my $API_KEY => 'abcdef1234567890abcdef1234567890';

my $module = Test::MockModule->new('Sailthru::Client');
# we'll use http_req_args to grab and hold on to the arguments passed in
my $http_req_args;
$module->mock(
    _http_request => sub {
        my $self = shift;
        $http_req_args = \@_;
        HTTP::Response->new(200);
        my $response = HTTP::Response->new(200);
        $response->content('{"error":"99","errormsg":"foobarbaz"}');
        return $response;
    }
);

my $sc = Sailthru::Client->new( $API_KEY, '00001111222233334444555566667777' );
isa_ok( $sc, 'Sailthru::Client' );

my %request_methods = (
    api_get    => 'GET',
    api_post   => 'POST',
    api_delete => 'DELETE',
);
for my $method ( keys %request_methods ) {
    my $req_type = $request_methods{$method};
    my $action   = 'foobarbaz';
    my %opts     = my %save_opts = ( test => 'arg' );
    # clear saved args from mock
    $http_req_args = undef;
    # is the method in the module?
    can_ok( $sc, $method );
    lives_ok( sub { $sc->$method( $action, \%opts ) }, "$method lives" );
    # see if the API action is in the url accessed
    my $uri = URI->new( $http_req_args->[0] );
    is( $uri->path, "/$action", "$method: api '$action' was called" );
    # make sure the http request verb matches
    is( $http_req_args->[2], $req_type, "$method: request type $req_type was called" );
    # make sure the argument hash that was passed in wasn't munged
    is_deeply( \%opts, \%save_opts, "$method opts weren't overwritten" );
}

done_testing;
