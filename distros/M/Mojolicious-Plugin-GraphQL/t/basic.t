use strict;
use warnings;
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::More;
use Mojolicious::Lite;
use GraphQL::Schema;

my $schema = GraphQL::Schema->from_doc(<<'EOF');
type Query {
  helloWorld: String
}
EOF
plugin GraphQL => {
  convert => [ 'Test' ],
  graphiql => 1,
};
plugin GraphQL => {endpoint => '/graphql2', handler => sub {
  my ($c, $body, $execute) = @_;
  # returns JSON-able Perl data
  $execute->(
    $schema,
    $body->{query},
    { helloWorld => 'Hello, world!' }, # $root_value
    $c->req->headers,
    $body->{variables},
    $body->{operationName},
    undef, # $field_resolver
  );
}};
plugin GraphQL => {endpoint => '/graphql-live-and-let-die', handler => sub {
  die "I died!\n" }};
plugin GraphQL => {
  endpoint => '/graphql-promise',
  schema => $schema,
  root_value => { helloWorld => sub {
    my $promise = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.5 => sub { $promise->resolve('Yo') });
    $promise->then(sub { "$_[0]!" });
  } },
};

use Test::Mojo;
my $t = Test::Mojo->new;

subtest 'GraphiQL' => sub {
  $t->get_ok('/graphql', {
    Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  })->content_like(qr/React.createElement\(GraphiQL/, 'Content as expected');
  $t->get_ok('/graphql?query=%23%20Welcome%0A%7BhelloWorld%7D', {
    Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  })->content_like(qr/query: "# Welcome/, 'Content en/decodes right');
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

subtest 'GraphQL with promise' => sub {
  my $tm = $t->post_ok('/graphql-promise',
    { Content_Type => 'application/json' },
    '{"query":"{helloWorld}"}',
  )->json_is(
    { 'data' => { 'helloWorld' => 'Yo!' } },
  );
};

subtest 'GraphQL with JSON error' => sub {
  my $tm = $t->post_ok('/graphql-promise',
    { Content_Type => 'application/json' },
    '{"query":"{helloWorld}""}',
  )->content_like(
    qr/Malformed JSON: Expected comma/
  );
};

done_testing;
