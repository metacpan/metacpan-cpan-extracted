use Test::Most;

use aliased 'OpenTracing::Implementation::DataDog::Client';
use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use JSON::MaybeXS;

use lib 't/lib';
use UserAgent::Fake;

subtest "Create a span and capture the request" => sub {
    
    my $some_span_context;
    lives_ok {
        $some_span_context = SpanContext->new(
            service_name    => 'srvc name',
            resource_name   => 'rsrc name',
            baggage_items   => { foo => 1, bar => 2 },
        )->with_span_id(54365)->with_trace_id(87359);
    } "Created 'some_span_context"
    
    or return;
    
    my $this_span_context;
    lives_ok {
        $this_span_context = $some_span_context->new_clone(
        )->with_span_id(49603)->with_trace_id($some_span_context->trace_id);
    } "Created 'this_span_context'"
    
    or return;
    
    my $test_span;
    lives_ok {
        $test_span = Span->new(
            operation_name  => 'oprt name',
            child_of        => $some_span_context,
            context         => $this_span_context,
            start_time      => 52.750,
            tags            => { baz => 3, qux => 4 },
        );
    } "Created 'test_span'"
    
    or return;
    
    lives_ok {
        $test_span->finish( 83.500 );
    } " Did finish the 'test_span'"
    
    or return;
    
    my $http_user_agent;
    lives_ok {
        $http_user_agent = UserAgent::Fake->new
    } "Created a mocked 'http_user_agent'"
    
    or return;
    
    my $datadog_client;
    lives_ok {
        $datadog_client = Client->new(
            http_user_agent => $http_user_agent,
            scheme          => 'https',
            host            => 'test-host',
            port            => '1234',
            path            => 'my/traces',
        ) # we do need defaults here, to not break when ENV was set already
    } "Created a 'datadog_client'"
    
    or return;
    
    my $send_ok;
    lives_ok {
        $send_ok = $datadog_client->send_span( $test_span )
    } "Did 'send_span'"
    
    or return;
    
    ok $send_ok, "... which returned okay";
    
    my @requests = $http_user_agent->get_all_requests();
    my $test_request = $requests[0];
    my $content = $test_request->decoded_content;
    
    my $struct = decode_json $content;
    
    cmp_deeply(
        $struct => [
            [
                {
                    duration    => 30750000000,
                    meta        => {
                        bar         => 2,
                        baz         => 3,
                        foo         => 1,
                        qux         => 4,
                    },
                    name        => "oprt name",
                    parent_id   => 54365,
                    resource    => "rsrc name",
                    service     => "srvc name",
                    span_id     => 49603,
                    start       => 52750000000,
                    trace_id    => 87359,
                    type        => "custom",
                }
            ]
        ],
        "... and most importanly, did send of the right JSON string"
    );
    
};

done_testing();
