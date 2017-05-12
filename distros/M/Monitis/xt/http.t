use lib 't/lib';
use Test::Monitis tests => 18, agent => 1;

note 'Action addInternalHttpMonitor (http->add, type: POST)';

my $response = api->http->add(
    userAgentId        => agent->{id},
    contentMatchFlag   => 1,
    contentMatchString => 'Monitis',
    httpMethod         => 1,
    postData           => 'q=monitis',
    userAuth           => '',
    passAuth           => '',
    timeout            => 3000,
    redirect           => 0,
    url                => 'google.com',
    name               => 'Google',
    tag                => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

my $monitor_id = $response->{data}{testId};

note 'Action addInternalHttpMonitor (http->add, type: GET)';
$response = api->http->add(
    userAgentId        => agent->{id},
    contentMatchFlag   => 1,
    contentMatchString => 'Googletest',
    httpMethod         => 0,
    postData           => 'q=monitis',
    userAuth           => '',
    passAuth           => '',
    timeout            => 1000,
    redirect           => 1,
    url                => 'monitis.com',
    name               => 'Google-GET',
    tag                => 'test_from_api'
);

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

# Cleanup

api->internal_monitors->delete(
    testIds => $response->{data}{testId},
    type    => 4
) if $response->{status} eq 'ok';

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';
like $response->{data}{testId}, qr/^\d+$/, 'API returned test id';

note 'Action agentInternalHttp (http->get)';

$response = api->http->get(agentId => agent->{id});

isa_ok $response, 'ARRAY', 'JSON response ok';
my ($exists) =
  grep { $_->{id} == $monitor_id } @$response;

ok $exists, 'monitor exists';

$monitor_id ||= $response->[0]{id};

SKIP: {
    skip "Monitor ID required for this tests", 7 unless $monitor_id;

    note 'Action editInternalHttpMonitor (http->edit)';

    $response = api->http->edit(
        testId             => $monitor_id,
        contentMatchString => 'Google',
        httpMethod         => 1,
        userAuth           => '',
        passAuth           => '',
        postData           => 'q=Monitis',
        timeout            => 500,
        urlParams          => '',
        name               => 'Google',
        tag                => 'test_from_api'
    );

    isa_ok $response, 'HASH', 'JSON response ok';
    is $response->{status}, 'ok', 'status ok';


    note 'Action InternalHttpInfo (http->get_info)';

    $response = api->http->get_info(monitorId => $monitor_id);

    isa_ok $response, 'HASH', 'JSON response ok';
    is $response->{id}, $monitor_id, 'response id ok';


    note 'Action httpResult (http->get_results)';

    $response = api->http->get_results(
        monitorId => $monitor_id,
        day       => (localtime)[3],
        month     => (localtime)[4] + 1,
        year      => (localtime)[5] + 1900
    );

    isa_ok $response, 'HASH', 'JSON response ok';

    note 'Action tophttp (http->get_top_results)';

    note 'Cleanup';

    $response =
      api->internal_monitors->delete(testIds => $monitor_id, type => 4);

    isa_ok $response, 'HASH', 'JSON response ok';
    is $response->{status}, 'ok', 'monitor deleted';

}
