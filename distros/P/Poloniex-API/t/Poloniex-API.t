# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Poloniex-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More qw(no_plan);
use Poloniex::API;

BEGIN {
    use_ok('Poloniex::API');
    eval { use Test::MockObject; 1 }
      || plan skip_all => 'Poloniex::API required for this test!';
    eval { use JSON::XS; 1 } 
      || plan skip_all => 'JSON::XS not installet!';
}

$ENV{DEBUG_API_POLONIEX} = 1;

my @test = (
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'{"BTC_LTC":{"last":"0.0251","lowestAsk":"0.02589999","highestBid":"0.0251","percentChange":"0.02390438", "baseVolume":"6.16485315","quoteVolume":"245.82513926"}}',
        },
        method => 'returnTicker',
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'{"BTC_LTC":{"BTC":"2.23248854","LTC":"87.10381314"},"BTC_NXT":{"BTC":"0.981616","NXT":"14145"}, "totalBTC":"81.89657704","totalLTC":"78.52083806"}'
        },
        method => 'return24Volume',
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'{"asks":[[0.00007600,1164],[0.00007620,1300] ], "bids":[[0.00006901,200],[0.00006900,408] ], "isFrozen": 0, "seq": 18849}'
        },
        method => 'returnOrderBook',
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'[{"date":"2014-02-10 04:23:23","type":"buy","rate":"0.00007600","amount":"140","total":"0.01064"},{"date":"2014-02-10 01:19:37","type":"buy","rate":"0.00007600","amount":"655","total":"0.04978"}]'
        },
        method => 'returnTradeHistory',
        request_args =>
          { currencyPair => 'BTC_NXT', start => 1410158341, end => 1410499372 },
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'[{"date":1405699200,"high":0.0045388,"low":0.00403001,"open":0.00404545,"close":0.00427592,"volume":44.11655644, "quoteVolume":10259.29079097,"weightedAverage":0.00430015}]'
        },
        method       => 'returnChartData',
        request_args => {
            currencyPair => 'BTC_XMR',
            start        => 1405699200,
            end          => 9999999999,
            period       => 14400
        },
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'{"1CR":{"maxDailyWithdrawal":10000,"txFee":0.01,"minConf":3,"disabled":0},"ABY":{"maxDailyWithdrawal":10000000,"txFee":0.01,"minConf":8,"disabled":0}}'
        },
        method => 'returnCurrencies',
    },
    {
        agent => \&lwp_mock,
        resp  => {
            result =>
'{"offers":[{"rate":"0.00200000","amount":"64.66305732","rangeMin":2,"rangeMax":8} ],"demands":[{"rate":"0.00170000","amount":"26.54848841","rangeMin":2,"rangeMax":2} ]}'
        },
        method       => 'returnLoanOrders',
        request_args => { currency => 'BTC' }
    },
);

my $api = Poloniex::API->new(
    APIKey => 'YOUR-API-KEY-POLONIEX',
    Secret => 'YOUR-SECRET-KEY-POLONIEX'
);

foreach my $test (@test) {
    ++$test->{resp}{ok};

    # variables not used $mock_response, @call_order
    my ( $mock_agent ) =
      $test->{agent}->( $test->{resp} );
    $api->{_agent} = $mock_agent;
    my $method = $test->{method};

    my $mock_tester = sub {
        my $return_value = shift;

        is_deeply $return_value,
          JSON::XS->new->decode( $test->{resp}->{result} ),
          "return value of '$method' is as expected";
    };
    note("running tests for $test->{method}");
    $mock_tester->(
        $api->api_public( $method, $test->{request_args} || undef ) );
}

sub lwp_mock {
    my $response      = shift;
    my $mock_response = Test::MockObject->new;

    $mock_response->set_true('is_success');
    $mock_response->set_always( 'decoded_content', $response->{result} );

    my $mock_agent = Test::MockObject->new;

    $mock_agent->set_always( 'post', $mock_response );
    $mock_agent->set_isa('LWP::UserAgent');

    ( $mock_agent, $mock_response, 'decoded_content', 'is_success' );
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

