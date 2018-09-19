use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

ok my $fetch = Net::Curl::Parallel->new(slots => 2, connect_timeout => 1000, request_timeout => 2000), 'new';
is [$fetch->add(HTTP::Request->new(GET => 'http://www.example.com'), HTTP::Request->new(GET => 'http://www.example.com'))], [0, 1], 'add HTTP::Request';
is [$fetch->add(GET => 'http://www.example.com')], [2], 'add HTTP::Request args';
is [$fetch->try(GET => 'http://www.example.ihopethisneverbecomesarealtldorthistestwillbreak')], [3], 'try';
is scalar @{$fetch->requests}, 4, 'request count';
is scalar @{$fetch->responses}, 0, 'response count';

SKIP: {
  skip 'Network tests disabled; enable them with NET_CURL_PARALLEL_NETWORK_TESTS=1', 1
    unless $ENV{NET_CURL_PARALLEL_NETWORK_TESTS};

  subtest 'perform' => sub{
    is $fetch->perform, 4, 'perform';
    is scalar @{$fetch->responses}, 4, 'response count';

    my $expected_responses = array{
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') && !$_->failed });
      item validator(sub{ isa_ok($_, 'Net::Curl::Parallel::Response') &&  $_->failed });
    };

    my $responses = $fetch->collect;
    is $responses, $expected_responses, 'collect array';
    is [$fetch->collect], $expected_responses, 'collect list';

    my $res = $fetch->collect(0);
    isa_ok $res, 'Net::Curl::Parallel::Response';
  };
};

done_testing;
