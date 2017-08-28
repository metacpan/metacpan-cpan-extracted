use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use Mojo::XMLRPC qw[encode_xmlrpc decode_xmlrpc];

post '/' => sub {
  my $c = shift;
  my $message = decode_xmlrpc($c->req->body);
  unless ($message->method_name eq 'echo') {
    return $c->render(data => encode_xmlrpc(fault => 400, 'Only echo is supported'));
  }
  $c->render(data => encode_xmlrpc(response => @{ $message->parameters }));
};

my $t = Test::Mojo->new;

subtest 'fault' => sub {
  $t->post_ok('/', encode_xmlrpc(call => 'notecho', 42))
    ->status_is(200);
  my $response = decode_xmlrpc($t->tx->res->body);

  isa_ok $response, 'Mojo::XMLRPC::Message::Response', 'correct response type';
  ok $response->is_fault, 'reponse is a fault';
  my %expect = (
    faultCode => 400,
    faultString => 'Only echo is supported',
  );
  is_deeply $response->fault, \%expect, 'correct fault response';
};

subtest 'success' => sub {
  $t->post_ok('/', encode_xmlrpc(call => 'echo', 42))
    ->status_is(200);
  my $response = decode_xmlrpc($t->tx->res->body);

  isa_ok $response, 'Mojo::XMLRPC::Message::Response', 'correct response type';
  ok !$response->is_fault, 'reponse is not a fault';
  is_deeply $response->parameters, [42], 'correct response parameters';
};

done_testing;

