use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::Resub qw(resub);
use HTTP::Request;

require_ok('PrankCall');

my $class = 'PrankCall';
my $version = $PrankCall::VERSION;
my $user_agent = 'PrankCall/' . $version;

subtest 'get_tests' => sub {
  my ($socket_new_call, $remote_test) = generate_test_socket();

  my $obj = $class->new(host => 'http://127.0.0.1', port => 3450);
  $obj->get(path => '/', params => { 'foo' => 'bar' });

  ok $socket_new_call->called;
  my ($name, $args);
  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "GET /?foo=bar HTTP/1.1\nHost: 127.0.0.1\nUser-Agent: $user_agent\nContent-Type: application/x-www-form-urlencoded\n\n";

  ($name, $args) = $remote_test->next_call;
  is $name, "close";
};

subtest 'get_tests_with_request_obj' => sub {
  my ($socket_new_call, $remote_test) = generate_test_socket();

  my $obj = $class->new;
  $obj->get( request_obj => HTTP::Request->new(GET => join('/', 'http://127.0.0.1:1212', 'http_request')));

  ok $socket_new_call->called;
  my ($name, $args);
  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "GET /http_request\n\n";

  ($name, $args) = $remote_test->next_call;
  is $name, "close";
};

subtest 'post_tests' => sub {
  my ($socket_new_call, $remote_test) = generate_test_socket();

  my $obj = $class->new;
  $obj->post( request_obj => HTTP::Request->new(POST => join('/', 'http://127.0.0.1:4334', 'http_post_request')));

  ok $socket_new_call->called;
  my ($name, $args);
  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "POST /http_post_request\n\n";

  ($name, $args) = $remote_test->next_call;
  is $name, "close";
};

subtest 'post_tests_body_redial' => sub {
  my ($socket_new_call, $remote_test) = generate_test_socket();

  my $obj = $class->new(host => 'http://127.0.0.1', port => 31214, cache_socket => 1, timeout => 10);
  $obj->post( path => '/http_post_request_with_body', body => { foo => 'bar' }, callback => sub {
    my ($prank, $error) = @_;
    $prank->redial;
  });

  ok $socket_new_call->called;
  my ($name, $args);

  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "POST /http_post_request_with_body HTTP/1.1\nHost: 127.0.0.1\nUser-Agent: $user_agent\nContent-Length: 7\nContent-Type: application/x-www-form-urlencoded\n\nfoo=bar\n";

  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "POST /http_post_request_with_body HTTP/1.1\nHost: 127.0.0.1\nUser-Agent: $user_agent\nContent-Length: 7\nContent-Type: application/x-www-form-urlencoded\n\nfoo=bar\n";

  # Close should not be called since we're caching.
  ($name, $args) = $remote_test->next_call;
  is $name, undef;
};

subtest 'override_useragent' => sub {
  my ($socket_new_call, $remote_test) = generate_test_socket();
  PrankCall->import(user_agent => 'foo');

  my $obj = $class->new(host => 'http://127.0.0.1', port => 3450);
  $obj->get(path => '/', params => { 'foo' => 'bar' });

  ok $socket_new_call->called;
  my ($name, $args);
  ($name, $args) = $remote_test->next_call;
  is $name, 'autoflush';
  is $args->[-1], 1;

  ($name, $args) = $remote_test->next_call;
  is $name, "syswrite";
  is $args->[-1], "GET /?foo=bar HTTP/1.1\nHost: 127.0.0.1\nUser-Agent: foo\nContent-Type: application/x-www-form-urlencoded\n\n";
};

done_testing;

sub generate_test_socket {
  my $remote_test = Test::MockObject->new;
  $remote_test->mock('autoflush', sub { return 1 });
  $remote_test->mock('syswrite', sub { return 1 });
  $remote_test->mock('close', sub { my $self = shift; undef $self; });
  my $socket_new_call = resub 'IO::Socket::INET::new', sub { return $remote_test };
  return ($socket_new_call, $remote_test);
}
