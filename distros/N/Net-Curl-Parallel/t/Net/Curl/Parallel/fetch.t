use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

subtest 'Skip guard' => sub {
    unless ($ENV{NET_CURL_PARALLEL_NETWORK_TESTS}) {
      plan skip_all => 'Enable network tests with NET_CURL_PARALLEL_NETWORK_TESTS=1'
  }

  subtest 'Class method' => sub {
    my $invoker = 'Net::Curl::Parallel';

    my $res = $invoker->fetch(GET => 'http://www.example.com');
    ok $res, 'fetch returns a response';
    isa_ok $res, 'Net::Curl::Parallel::Response';
  };

  subtest 'Obj method' => sub {
    my $invoker = Net::Curl::Parallel->new;

    my $res = $invoker->fetch(GET => 'http://www.example.com');
    ok $res, 'fetch returns a response';
    isa_ok $res, 'Net::Curl::Parallel::Response';
  };
};

done_testing;
