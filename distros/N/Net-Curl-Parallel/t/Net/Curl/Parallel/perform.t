use Test2::V0;
use Test2::API qw(context);
use Test2::Tools::Spec;
use Test2::Tools::Explain;
use Test2::Plugin::SpecDeclare;
use strictures 2;

use HTTP::Request;
use Types::Standard -types;
use Net::Curl::Parallel;

use Test::HTTP::MockServer;

subtest 'perform with no requests' => sub {
  my $f = Net::Curl::Parallel->new;

  my @responses = $f->perform;
  is [@responses], [], 'empty perform does no responses';
};

subtest 'perform with one request' => sub {
  my $f = Net::Curl::Parallel->new;

  my $server = Test::HTTP::MockServer->new;
  $f->add(GET => $server->url_base);

  $server->start_mock_server(sub {
    my ($req, $res) = @_;

    $res->content('hello');

    return $res;
  });

  my @responses = $f->perform;

  $server->stop_mock_server;

  is [map { $_->content } @responses], ['hello'], 'perform with one request';
};

subtest 'perform with two requests' => sub {
  my $f = Net::Curl::Parallel->new;

  my $server = Test::HTTP::MockServer->new;
  $f->add(GET => $server->url_base);

  my $server2 = Test::HTTP::MockServer->new;
  $f->add(GET => $server2->url_base);

  $server->start_mock_server(sub {
    my ($req, $res) = @_;

    $res->content('hello from 1');

    return $res;
  });
  $server2->start_mock_server(sub {
    my ($req, $res) = @_;

    $res->content('hello from 2');

    return $res;
  });

  my @responses = $f->perform;

  $server->stop_mock_server;
  $server2->stop_mock_server;

  is [map { $_->content } @responses], ['hello from 1', 'hello from 2'], 'perform with two requests';
};

done_testing;
