package Coffee::Server::REST;

use Object::Pad;

class Coffee::Server::REST extends IO::Async::Notifier;


use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Net::Async::HTTP::Server;
use HTTP::Response;
use JSON::MaybeUTF8 qw(:v1);
use Unicode::UTF8;
use Scalar::Util qw(refaddr blessed);
use curry;

use Log::Any qw($log);

=head1 NAME

Coffee Manager REST API Service

=head1 DESCRIPTION

Provides an HTTP interface to Coffee Manager.

=cut

has $server;
has $listen_port;
has $active_requests;
has $requests_sink;

method configure (%args) {

    $listen_port = delete $args{listen_port} if exists $args{listen_port};
    $active_requests = {};

    return $self->next::method(%args);
}


method _add_to_loop ($loop) {
    # server for incoming requests
    $self->add_child(
        $server = Net::Async::HTTP::Server->new(
            on_request => $self->$curry::weak( method ($http, $req) {
                # Keep request in memory until we respond to it.
                my $k = refaddr($req);
                $active_requests->{$k} = $self->handle_http_request($req)->on_ready(
                    $self->$curry::weak( method ($f) {
                        delete $active_requests->{$k};
                    })
                );
            }),
        )
    );
}


async method handle_http_request ($req) {
    $log->debugf('HTTP receives %s %s:%s', $req->method, $req->path, $req->body);
    try {
        # Capture only alphabetical names as path, and numerics as parameters.
        my ($service, @path) = ($req->path =~ /\/([A-Za-z]+)/g);

        # add default method, if no method supplied.
        push @path, 'request' unless @path;
        # Construct method name from path
        my $method = join('_', @path);

        my %params = ($req->path =~ /\/([0-9]+)/g);
        # If no params are passed on requirement structure
        # Check if params passed as query params.
        if (!%params) {
             %params = $req->query_form;
        }
        my $body_params = decode_json_utf8($req->body || '{}');

        $log->tracef('Had body_params %s | params %s | for service %s, method: %s | path: %s', $body_params, \%params, $service, $method, \@path);

        $requests_sink->emit({request => $req, service => $service, method => $method, params => \%params, body => $body_params, type => $req->method});
    } catch ($e) {
        $log->errorf('Failed with handling request - %s', $e);
        $self->reply_fail($req, $e);
    }
}

method reply_success ($req, $data) {
    my $response = HTTP::Response->new(200);

    $response->add_content(encode_json_utf8($data));
    $response->content_type("application/json");
    $response->content_length(length $response->content);

    $req->respond($response);
}

method reply_fail ($req, $error) {

    my $content = {error_code => '400', error_text => ''};
    $content->{error_text} = $error;

    my $response = HTTP::Response->new($content->{error_code});
    $response->add_content(encode_json_utf8($content));
    $response->content_type("application/json");
    $response->content_length(length $response->content);

    $req->respond($response);
}

async method start ($sink) {
    
    $requests_sink = $sink;
    my $listner = await $server->listen(
        addr => {
            family   => 'inet',
            socktype => 'stream',
            port     => $listen_port});
    my $port = $listner->read_handle->sockport;

    $log->debugf('HTTP REST API service is listening on port %s', $port);
    return $port;
}

1;
