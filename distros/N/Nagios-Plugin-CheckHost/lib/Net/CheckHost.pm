package Net::CheckHost;

use strict;
use warnings;

our $VERSION = 0.05;

use JSON;
use LWP::UserAgent;
use URI;

sub new {
    my ($class, @args) = @_;

    bless {
        gateway   => 'https://check-host.net/',
        ua        => LWP::UserAgent->new,
        @args
    }, $class;
}

sub prepare_request {
    my ($self, $request, %args) = @_;

    my $uri = URI->new($self->{gateway});
    $uri->path($uri->path . $request);
    $uri->query_form(%args);

    my $method = 'GET';

    HTTP::Request->new(
        'GET' => $uri, [
            'User-Agent'   => 'Nagios::Plugin::CheckHost v' . $VERSION,
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ]
    );
}

sub request {
    my $self = shift;

    my $http_response = $self->{ua}->request($self->prepare_request(@_));
    Carp::croak($http_response->status_line)
      unless $http_response->is_success;

    my $response = decode_json($http_response->decoded_content);

    if ($response->{error}) {
        my $error = $response->{error};
        Carp::croak("API error $error");
    }

    $response;
}

1;
