package BrokerTestApp;
use JSON::XS;

my $app = sub {
    my ($env) = @_;

    my $body;
    (delete $env->{'psgi.input'})->read($body,1000000);
    my $data = JSON::XS::decode_json($body);
    my $response = {};

    exit 0 if $data->{exit_now};

    $response->{path_info} = $env->{PATH_INFO};

    if ($data->{reply_to}) {
        return [ 200, [
            'X-STOMP-Reply-Address' => $data->{reply_to},
        ], [
            JSON::XS::encode_json($response)
        ] ];
    }

    return [ 200, [], ['nothing'] ];
};

sub get_app { $app }

1;
