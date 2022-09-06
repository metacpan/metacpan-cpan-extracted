package Coffee::Manager::API;

use Myriad::Service;
use Coffee::Server::REST;

has $http_server;
has $ryu;
has $running_sink;

async method startup () {
    $self->add_child(
        $ryu =  Ryu::Async->new()
    );
    $self->add_child(
        $http_server = Coffee::Server::REST->new(listen_port => 80)
    );

    my $sink = $ryu->sink(label => "http_requests_sink");
    $running_sink = $sink->source->map(
        $self->$curry::weak(async method ($incoming_req) {
            my $req = delete $incoming_req->{request};
            $log->debugf('Incoming request to http_requests_sink | %s', $incoming_req);
            try {
                my $service_response = await $self->request_service($incoming_req);
                if ( exists $service_response->{error} ) {
                    $http_server->reply_fail($req, $service_response->{error});
                } else {
                    $http_server->reply_success($req, $service_response);
                }
            } catch ($e) {
                $log->warnf('Outgoing failed reply to HTTP request %s', $e);
                $http_server->reply_fail($req, $e);
            }
        }
    ))->resolve->completed;
    await $http_server->start($sink);
}

async method request_service ($incoming_req) {
    # In fact hash can be passed as it is, however it is kept for clarity.
    my ($service_name, $method, $params, $body, $type) = @$incoming_req{qw(service method params body type)};
    my $service = $api->service_by_name(join '.', 'coffee.manager', $service_name);
    return await $service->call_rpc($method, params => $params, body => $body, type => $type);
}

1;
