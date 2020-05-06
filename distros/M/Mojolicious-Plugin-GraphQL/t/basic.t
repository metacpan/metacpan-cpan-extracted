use strict;
use warnings;
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use GraphQL::Schema;

# constants
my $schema = GraphQL::Schema->from_doc(<<'EOF');
type Query {
  helloWorld: String
}
EOF
my $t = Test::Mojo->new;
my %helloWorld_query = (json => {query => "{helloWorld}"});
my %accept_html = (
  Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
);

# implicitly /graphql
plugin GraphQL => {
  convert => [ 'Test' ],
  graphiql => 1,
};
subtest 'GraphiQL' => sub {
  $t->get_ok(
    '/graphql', \%accept_html
  )->content_like(qr/React.createElement\(GraphiQL/, 'Content as expected');
  $t->get_ok(
    '/graphql?query=%23%20Welcome%0A%7BhelloWorld%7D', \%accept_html
  )->content_like(qr/query: "# Welcome/, 'Content en/decodes right');
};
subtest 'GraphQL with POST' => sub {
  $t->post_ok('/graphql', %helloWorld_query)->json_is(
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
  );
};

plugin GraphQL => {
  endpoint => '/graphql2',
  schema => $schema,
  handler => sub {
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
  },
};
subtest 'GraphQL with route-handler' => sub {
  $t->post_ok('/graphql2', %helloWorld_query)->json_is(
    { 'data' => { 'helloWorld' => 'Hello, world!' } },
  );
};

plugin GraphQL => {
  endpoint => '/graphql-live-and-let-die',
  schema => $schema, handler => sub { die "I died!\n" },
};
subtest 'GraphQL with die' => sub {
  $t->post_ok('/graphql-live-and-let-die', %helloWorld_query)->json_is(
    { errors => [ { message => "I died!\n" } ] },
  );
};

plugin GraphQL => {
  endpoint => '/graphql-promise',
  schema => $schema,
  root_value => { helloWorld => sub {
    my $promise = Mojo::Promise->new;
    Mojo::IOLoop->timer(0.5 => sub { $promise->resolve('Yo') });
    $promise->then(sub { "$_[0]!" });
  } },
};
subtest 'GraphQL with promise' => sub {
  $t->post_ok('/graphql-promise', %helloWorld_query)->json_is(
    { 'data' => { 'helloWorld' => 'Yo!' } },
  );
};
subtest 'GraphQL with JSON error' => sub {
  $t->post_ok('/graphql-promise',
    { Content_Type => 'application/json' },
    '{"query":"{helloWorld}""}',
  )->json_is(
    {"errors" => [{"message" => "Malformed request"}]}
  );
};

plugin GraphQL => {
  endpoint => '/graphql-subs',
  graphiql => 1,
  convert => [
    'Test',
    sub {
      my $text = $_[1]->{s};
      require GraphQL::AsyncIterator;
      my $ai = GraphQL::AsyncIterator->new(
        promise_code => Mojolicious::Plugin::GraphQL->promise_code,
      );
      my ($i, $cb) = 0;
      $cb = sub {
        eval { $ai->publish({ timedEcho => $text }) };
        return $ai->close_tap if $@ or $i++ >= 2;
        Mojo::IOLoop->timer(0.1 => $cb);
      };
      $cb->();
      $ai;
    },
  ],
};
subtest 'GraphiQL subs' => sub {
  $t->get_ok(
    '/graphql-subs', \%accept_html
  )->content_like(qr/SubscriptionsTransportWs/, 'Content has subs stuff');
};
subtest 'subs response' => sub {
  my $wsp = Mojolicious::Plugin::GraphQL->ws_protocol;
  my $init = { payload => {}, type => $wsp->{GQL_CONNECTION_INIT} };
  my $ack = { payload => {}, type => $wsp->{GQL_CONNECTION_ACK} };
  my $start1 = {
    payload => { query => 'subscription s { timedEcho(s: "yo") }' },
    type => $wsp->{GQL_START},
    id => 1,
  };
  my $datayo1 = {
    payload => { data => { timedEcho => 'yo' } },
    type => $wsp->{GQL_DATA},
    id => 1,
  };
  my $stop1 = {
    payload => {}, type => $wsp->{GQL_STOP},
    id => 1,
  };
  my $complete1 = {
    payload => {},
    type => $wsp->{GQL_COMPLETE},
    id => 1,
  };
  my $start2 = { %$start1, id => 2 };
  my $datayo2 = { %$datayo1, id => 2 };
  my $complete2 = { %$complete1, id => 2 };
  $t->websocket_ok('/graphql-subs')
    ->send_ok({json => $init})
    ->message_ok->json_message_is($ack)
    ->send_ok({json => $start1})
    ->message_ok->json_message_is($datayo1)
    ->or(sub { diag explain $t->message })
    ->send_ok({json => $stop1})
    ->message_ok->json_message_is($complete1)
    ->finish_ok;
  $t->websocket_ok('/graphql-subs')
    ->send_ok({json => $init})
    ->message_ok->json_message_is($ack)
    ->send_ok({json => $start2})
    ->message_ok->json_message_is($datayo2)
    ->message_ok->json_message_is($datayo2)
    ->message_ok->json_message_is($datayo2)
    ->message_ok->json_message_is($complete2)
    ->finish_ok;
};

done_testing;
