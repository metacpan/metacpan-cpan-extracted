use strict;
use warnings;
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::More;
use Mojolicious::Lite;
use GraphQL::Schema;
use GraphQL::Type::Object;
use GraphQL::Type::Scalar qw/ $String /;

my $schema = GraphQL::Schema->new(
  query => GraphQL::Type::Object->new(
    name => 'QueryRoot',
    fields => {
      helloWorld => {
        type => $String,
        resolve => sub { 'Hello, world!' },
      },
    },
  ),
);
plugin GraphQL => {schema => $schema, graphiql => 1};
plugin GraphQL => {endpoint => '/graphql2', handler => sub {
  my ($c, $body, $execute) = @_;
  # returns JSON-able Perl data
  $execute->(
    $schema,
    $body->{query},
    undef, # $root_value
    $c->req->headers,
    $body->{variables},
    $body->{operationName},
    undef, # $field_resolver
  );
}};
plugin GraphQL => {endpoint => '/graphql-live-and-let-die', handler => sub {
  die "I died!\n" }};

use Test::Mojo;
my $t = Test::Mojo->new;

subtest 'GraphiQL' => sub {
  my $res = $t->get_ok('/graphql', {
    Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  })->content_like(qr/React.createElement\(GraphiQL/, 'Content as expected');
};

subtest 'GraphQL with POST' => sub {
  $t->post_ok('/graphql', { Content_Type => 'application/json' },
    '{"query":"{helloWorld}"}',
  )->json_is(
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
  );
};

subtest 'GraphQL with route-handler' => sub {
  $t->post_ok('/graphql2', { Content_Type => 'application/json' },
    '{"query":"{helloWorld}"}',
  )->json_is(
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
  );
};

subtest 'GraphQL with die' => sub {
  $t->post_ok('/graphql-live-and-let-die',
    { Content_Type => 'application/json' },
    '{"query":"{helloWorld}"}',
  )->json_is(
    { errors => [ { message => "I died!\n" } ] },
  );
};

done_testing;
