use Test::Most;

use aliased 'OpenTracing::Implementation::DataDog::Client';
use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use JSON::MaybeXS;

use lib 't/lib';
use UserAgent::Fake;

subtest "Create a span and capture the request" => sub {
    
    my $test_span;
    lives_ok {
        $test_span = setup_test_span()
    } "Did setup 'test_span'"
    
    or return;
    
    my $datadog_client;
    lives_ok {
        $datadog_client = setup_datadog_client();
    } "Did setup 'datadog_client'"
    
    or return;

    my $http_user_agent = $datadog_client->http_user_agent;
    
    my $send_span_result;
    
    lives_ok {
        $send_span_result = $datadog_client->send_span( $test_span )
    } "Did 'send_span' 1";
    is $send_span_result, +1, "... which has been collected";
    
    lives_ok {
        $send_span_result = $datadog_client->send_span( $test_span )
    } "Did 'send_span' 2";
    is $send_span_result, -2, "... which caused both been flushed";
    
    is scalar $http_user_agent->get_all_requests(), 1,
        "... having made the http request";
    
    lives_ok {
        $http_user_agent->break_connection();
    } "Has now broken the connection";
    
    lives_ok {
        $send_span_result = $datadog_client->send_span( $test_span )
    } "Did 'send_span' 3";
    is $send_span_result, +1, "... which still collects spans";
    
    warning_like {
        $send_span_result = $datadog_client->send_span( $test_span )
    } qr /^DataDog::Client being halted due to an error \[.*\]$/
    , "Did 'send_span' 4 ... with a 'DataDog::Client error'";
    ok !defined($send_span_result), "... which failed to flush the buffer";
    
    is scalar $http_user_agent->get_all_requests(), 2,
        "... and did try to make a http request";
    
    # I know, we're peeking inside!!!
    is $datadog_client->_span_buffer_size(), 2,
        "... and have still 2 spans in the buffer";
    
    lives_ok {
        $send_span_result = $datadog_client->send_span( $test_span )
    } "Did 'send_span' 5";
    ok !defined($send_span_result), "... which failed to send a span again";
    
    is scalar $http_user_agent->get_all_requests(), 2,
        "... but was not due a http request";
    
    # I know, we're peeking inside!!!
    is $datadog_client->_span_buffer_size(), 2,
        "... and have still 2 spans in the buffer";
    
    undef $datadog_client;
    
    is scalar $http_user_agent->get_all_requests(), 2,
        "... and did not make any http request during 'DEMOLISH'";
 };

done_testing();



sub setup_test_span {
    
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
            # start_time      => 52.750,
            # tags            => { baz => 3, qux => 4 },
        );
    } "Created 'test_span'"
    
    or return;
    
    lives_ok {
        $test_span->finish( 83.500 );
    } "... and Did finish the 'test_span'"
    
    or return;
    
    return $test_span;
    
}

sub setup_datadog_client {
    
    my $http_user_agent;
    lives_ok {
        $http_user_agent = UserAgent::Fake->new
    } "Created a mocked 'http_user_agent'"
    
    or return;
    
    my $datadog_client;
    lives_ok {
        $datadog_client = Client->new(
            http_user_agent => $http_user_agent,
            agent_url       => 'https://test-host:1234/my/traces',
            span_buffer_threshold => 2,
        ) # we do need defaults here, to not break when ENV was set already
    } "Created a 'datadog_client'"
    
    or return;
    
    return $datadog_client;
    
}