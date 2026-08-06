package TestHarness;

use v5.36;
use Future::AsyncAwait;
use JSON::PP qw(decode_json);
use Exporter 'import';

our @EXPORT_OK = qw(run_request);

# Drives a PAGI::FastAPI app closure through a single request without a
# real server, and returns (status, decoded_body_or_undef, raw_body,
# response_headers_arrayref).
sub run_request ($pagi_app, %req) {
    my $method       = $req{method} // 'GET';
    my $path         = $req{path}   // '/';
    my $query_string = $req{query_string} // '';
    my $headers      = $req{headers} // [];
    my $body         = $req{body};

    my $receive = $body
        ? async sub { return { type => 'http.request', body => $body, more_body => 0 } }
        : async sub { return { type => 'http.request', more_body => 0 } };

    my ($sent_start, $sent_body);
    my $send = async sub ($event) {
        $sent_start = $event if $event->{type} eq 'http.response.start';
        $sent_body  = $event if $event->{type} eq 'http.response.body';
    };

    $pagi_app->(
        { type => 'http', method => $method, path => $path, query_string => $query_string, headers => $headers },
        $receive, $send,
    )->get;

    my $decoded;
    if (defined $sent_body->{body} && length $sent_body->{body}) {
        $decoded = eval { decode_json($sent_body->{body}) };
    }

    return ($sent_start->{status}, $decoded, $sent_body->{body}, $sent_start->{headers} // []);
}

1;
