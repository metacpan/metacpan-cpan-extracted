use lib 't/lib';
use Test::Monitis tests => 9, live => 1;

note 'Action suspendTransactionMonitor (transaction_monitors->suspend)';

my $response = api->transaction_monitors->suspend(tag => 'test');

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action activateTransactionMonitor (transaction_monitors->activate)';

$response = api->transaction_monitors->activate(tag => 'test');

isa_ok $response, 'HASH', 'JSON response ok';
is $response->{status}, 'ok', 'status ok';

note 'Action transactionTests (transaction_monitors->get)';

$response = api->transaction_monitors->get;

isa_ok $response, 'ARRAY', 'JSON response ok';

my $monitorid = $response->[0]{id};

TODO: {
    todo_skip "Need existing transaction monitor for this test", 4
      unless $monitorid;

    note
      'Action transactionTestInfo (transaction_monitors->get_monitor_info)';

    $response =
      api->transaction_monitors->get_monitor_info(monitorId => $monitorid);

    isa_ok $response, 'HASH', 'JSON response ok';

    note
      'Action transactionTestResult (transaction_monitors->get_monitor_result)';

    $response = api->transaction_monitors->get_monitor_result(
        monitorId => $monitorid,
        year      => '2011',
        month     => '5',
        day       => '30'
    );

    isa_ok $response, 'ARRAY', 'JSON response ok';

    my $resultid = $response->[0]{id};    #we don't have monitors in API

    note
      'Action transactionStepResult (transaction_monitors->get_step_result)';

    $response =
      api->transaction_monitors->get_step_result(resultId => $resultid);

    isa_ok $response, 'HASH', 'JSON response ok';

    note
      'Action transactionStepCapture (transaction_monitors->get_step_capture)';

    $response = api->transaction_monitors->get_step_capture(
        monitorId => $monitorid,
        resultId  => $resultid
    );


    note 'Action transactionTestResult (transaction_monitors->get_step_net)';

    $response = api->transaction_monitors->get_step_net(
        resultId => $resultid,
        year     => '2011',
        month    => '5',
        day      => '30'
    );

    isa_ok $response, 'HASH', 'JSON response ok';
}
