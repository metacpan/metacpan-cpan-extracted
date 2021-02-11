package Mojolicious::Plugin::GraphQL;
# ABSTRACT: a plugin for adding GraphQL route handlers
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json to_json);
use GraphQL::Execution qw(execute);
use GraphQL::Type::Library -all;
use GraphQL::Debug qw(_debug);
use Module::Runtime qw(require_module);
use Mojo::Promise;
use curry;
use Exporter 'import';

our $VERSION = '0.19';
our @EXPORT_OK = qw(promise_code);

use constant DEBUG => $ENV{GRAPHQL_DEBUG};
use constant promise_code => +{
  all => sub {
    # current Mojo::Promise->all only works on promises, force that
    my @promises = map is_Promise($_)
      ? $_ : Mojo::Promise->new->resolve($_),
      @_;
    # only actually works when first promise-instance is a
    # Mojo::Promise, so force it to be one. hoping will be fixed soon
    Mojo::Promise->all(@promises);
  },
  resolve => Mojo::Promise->curry::resolve,
  reject => Mojo::Promise->curry::reject,
  new => Mojo::Promise->curry::new,
};
# from https://github.com/apollographql/subscriptions-transport-ws/blob/master/src/message-types.ts
use constant ws_protocol => +{
  # no legacy ones like 'init'
  GQL_CONNECTION_INIT => 'connection_init', # Client -> Server
  GQL_CONNECTION_ACK => 'connection_ack', # Server -> Client
  GQL_CONNECTION_ERROR => 'connection_error', # Server -> Client
  # NOTE: The keep alive message type does not follow the standard due to connection optimizations
  GQL_CONNECTION_KEEP_ALIVE => 'ka', # Server -> Client
  GQL_CONNECTION_TERMINATE => 'connection_terminate', # Client -> Server
  GQL_START => 'start', # Client -> Server
  GQL_DATA => 'data', # Server -> Client
  GQL_ERROR => 'error', # Server -> Client
  GQL_COMPLETE => 'complete', # Server -> Client
  GQL_STOP => 'stop', # Client -> Server
};

my @DEFAULT_METHODS = qw(get post);
use constant EXECUTE => sub { $_[7] = promise_code(); goto &execute; };
use constant SUBSCRIBE => sub {
  splice @_, 7, 1, promise_code();
  goto &GraphQL::Subscription::subscribe;
};
sub make_code_closure {
  my ($schema, $root_value, $field_resolver) = @_;
  sub {
    my ($c, $body, $execute, $subscribe_resolver) = @_;
    $execute->(
      $schema,
      $body->{query},
      $root_value,
      $c->req->headers,
      $body->{variables},
      $body->{operationName},
      $field_resolver,
      $subscribe_resolver ? (undef, $subscribe_resolver) : (),
    );
  };
}

sub _safe_serialize {
  my $data = shift // return 'undefined';
  my $json = to_json($data);
  $json =~ s#/#\\/#g;
  return $json;
}

sub _graphiql_wrap {
  my ($wrappee, $use_subscription) = @_;
  sub {
    my ($c) = @_;
    if (
      # not as ignores Firefox-sent multi-accept: $c->accepts('', 'html') and
      ($c->req->headers->header('Accept')//'') =~ /^text\/html\b/ and
      !defined $c->req->query_params->param('raw')
    ) {
      my $p = $c->req->query_params;
      my $https = $c->req->is_secure;
      return $c->render(
        template => 'graphiql',
        layout => undef,
        title            => 'GraphiQL',
        graphiql_version => 'latest',
        queryString      => _safe_serialize( $p->param('query') ),
        operationName    => _safe_serialize( $p->param('operationName') ),
        resultString     => _safe_serialize( $p->param('result') ),
        variablesString  => _safe_serialize( $p->param('variables') ),
        subscriptionEndpoint => to_json(
          # if serialises to true (which empty-string will), turns on subs code
          $use_subscription
            ? $c->url_for->to_abs->scheme($https ? 'wss' : 'ws')
            : 0
        ),
      );
    }
    goto $wrappee;
  };
}

sub _decode {
  my ($bytes) = @_;
  my $body = eval { decode_json($bytes) };
  # conceal error info like versions from attackers
  return (0, { errors => [ { message => "Malformed request" } ] }) if $@;
  (1, $body);
}

sub _execute {
  my ($c, $body, $handler, $execute, $subscribe_fn) = @_;
  my $data = eval { $handler->($c, $body, $execute, $subscribe_fn) };
  return { errors => [ { message => $@ } ] } if $@;
  $data;
}

sub _make_route_handler {
  my ($handler) = @_;
  sub {
    my ($c) = @_;
    my ($decode_ok, $body) = _decode($c->req->body);
    return $c->render(json => $body) if !$decode_ok;
    my $data = _execute($c, $body, $handler, EXECUTE());
    return $c->render(json => $data) if !is_Promise($data);
    $data->then(sub { $c->render(json => shift) });
  };
}

sub _make_connection_handler {
  my ($handler, $subscribe_resolver, $context) = @_;
  sub {
    my ($c, $bytes) = @_;
    my ($decode_ok, $body) = _decode($bytes);
    return $c->send({json => {
      payload => $body,
      type => ($context->{connected}
        ? ws_protocol->{GQL_ERROR} : ws_protocol->{GQL_CONNECTION_ERROR}),
    }}) if !$decode_ok;
    my $msg_type = $body->{type};
    if ($msg_type eq ws_protocol->{GQL_CONNECTION_INIT}) {
      $context->{connected} = 1;
      $c->send({json => {
        type => ws_protocol->{GQL_CONNECTION_ACK}
      }});
      if ($context->{keepalive}) {
        my $cb;
        $cb = sub {
          return unless $c->tx and $context->{keepalive};
          $c->send({json => {
            type => ws_protocol->{GQL_CONNECTION_KEEP_ALIVE},
          }});
          Mojo::IOLoop->timer($context->{keepalive} => $cb);
        };
        $cb->();
      }
      return;
    } elsif ($msg_type eq ws_protocol->{GQL_START}) {
      $context->{id} = $body->{id};
      my $data = _execute(
        $c, $body->{payload}, $handler, SUBSCRIBE(), $subscribe_resolver,
      );
      return $c->send({json => {
        payload => $data, type => ws_protocol->{GQL_ERROR},
      }}) if !is_Promise($data);
      $data->then(
        sub {
          my ($result) = @_;
          if (!is_AsyncIterator($result)) {
            # subscription error
            $c->send({json => {
              payload => $result, type => ws_protocol->{GQL_ERROR},
              id => $context->{id},
            }});
            $c->finish;
            return;
          }
          my $promise;
          $context->{async_iterator} = $result->map_then(sub {
            DEBUG and _debug('MLPlugin.ai_cb', $context, @_);
            $c->send({json => {
              payload => $_[0],
              type => ws_protocol->{GQL_DATA},
              id => $context->{id},
            }});
            $promise = $context->{async_iterator}->next_p;
            $c->send({json => {
              type => ws_protocol->{GQL_COMPLETE},
              id => $context->{id},
            }}) if !$promise; # exhausted, tell client
          });
          $promise = $context->{async_iterator}->next_p; # start the process
        },
        sub {
          $c->send({json => {
            payload => $_[0], type => ws_protocol->{GQL_ERROR},
            id => $context->{id},
          }});
          $c->finish;
        },
      );
    } elsif ($msg_type eq ws_protocol->{GQL_STOP}) {
      $c->send({json => {
        type => ws_protocol->{GQL_COMPLETE},
        id => $context->{id},
      }});
      $context->{async_iterator}->close_tap if $context->{async_iterator};
      undef %$context; # relinquish our refcounts
    }
  }
}

sub _make_subs_route_handler {
  my ($handler, $subscribe_resolver, $keepalive) = @_;
  require GraphQL::Subscription;
  sub {
    my ($c) = @_;
    # without this, GraphiQL won't accept is valid
    my $sec_websocket_protocol = $c->tx->req->headers->sec_websocket_protocol;
    $c->tx->res->headers->sec_websocket_protocol($sec_websocket_protocol)
      if $sec_websocket_protocol;
    my %context = (keepalive => $keepalive);
    $c->on(text => _make_connection_handler($handler, $subscribe_resolver, \%context));
    $c->on(finish => sub {
      $context{async_iterator}->close_tap if $context{async_iterator};
      undef %context; # relinquish our refcounts
    });
  };
}

sub register {
  my ($self, $app, $conf) = @_;
  if ($conf->{convert}) {
    my ($class, @values) = @{ $conf->{convert} };
    $class = "GraphQL::Plugin::Convert::$class";
    require_module $class;
    my $converted = $class->to_graphql(@values);
    $conf = { %$conf, %$converted };
  }
  die "Need schema\n" if !$conf->{schema};
  my $endpoint = $conf->{endpoint} || '/graphql';
  my $handler = $conf->{handler} || make_code_closure(
    @{$conf}{qw(schema root_value resolver)}
  );
  push @{$app->renderer->classes}, __PACKAGE__
    unless grep $_ eq __PACKAGE__, @{$app->renderer->classes};
  my $route_handler = _make_route_handler($handler);
  $route_handler = _graphiql_wrap($route_handler, $conf->{schema}->subscription)
    if $conf->{graphiql};
  my $r = $app->routes;
  if ($conf->{schema}->subscription) {
    # must add "websocket" route before "any" because checked in define order
    my $subs_route_handler = _make_subs_route_handler(
      $handler, @{$conf}{qw(subscribe_resolver keepalive)},
    );
    $r->websocket($endpoint => $subs_route_handler);
  }
  $r->any(\@DEFAULT_METHODS => $endpoint => $route_handler);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::GraphQL - a plugin for adding GraphQL route handlers

=head1 SYNOPSIS

  my $schema = GraphQL::Schema->from_doc(<<'EOF');
  schema {
    query: QueryRoot
  }
  type QueryRoot {
    helloWorld: String
  }
  EOF

  # for Mojolicious substitute "plugin" with $app->plugin(...
  # Mojolicious::Lite (with endpoint under "/graphql")
  plugin GraphQL => {
    schema => $schema, root_value => { helloWorld => 'Hello, world!' }
  };

  # OR, equivalently:
  plugin GraphQL => {schema => $schema, handler => sub {
    my ($c, $body, $execute, $subscribe_fn) = @_;
    # returns JSON-able Perl data
    $execute->(
      $schema,
      $body->{query},
      { helloWorld => 'Hello, world!' }, # $root_value
      $c->req->headers,
      $body->{variables},
      $body->{operationName},
      undef, # $field_resolver
      $subscribe_fn ? (undef, $subscribe_fn) : (), # only passed for subs
    );
  }};

  # OR, with bespoke user-lookup and caching:
  plugin GraphQL => {schema => $schema, handler => sub {
    my ($c, $body, $execute, $subscribe_fn) = @_;
    my $user = MyStuff::User->lookup($app->request->headers->header('X-Token'));
    die "Invalid user\n" if !$user; # turned into GraphQL { errors => [ ... ] }
    my $cached_result = MyStuff::RequestCache->lookup($user, $body->{query});
    return $cached_result if $cached_result;
    MyStuff::RequestCache->cache_and_return($execute->(
      $schema,
      $body->{query},
      undef, # $root_value
      $user, # per-request info
      $body->{variables},
      $body->{operationName},
      undef, # $field_resolver
      $subscribe_fn ? (undef, $subscribe_fn) : (), # only passed for subs
    ));
  };

  # With GraphiQL, on /graphql
  plugin GraphQL => {schema => $schema, graphiql => 1};

=head1 DESCRIPTION

This plugin allows you to easily define a route handler implementing a
GraphQL endpoint, including a websocket for subscriptions following
Apollo's C<subscriptions-transport-ws> protocol.

As of version 0.09, it will supply the necessary C<promise_code>
parameter to L<GraphQL::Execution/execute>. This means your resolvers
can (and indeed should) return Promise objects to function
asynchronously. As of 0.15 these must be "Promises/A+" as subscriptions
require C<resolve> and C<reject> methods.

The route handler code will be compiled to behave like the following:

=over 4

=item *

Passes to the L<GraphQL> execute, possibly via your supplied handler,
the given schema, C<$root_value> and C<$field_resolver>. Note as above
that the wrapper used in this plugin will supply the hash-ref matching
L<GraphQL::Type::Library/PromiseCode>.

=item *

The action built matches POST / GET requests.

=item *

Returns GraphQL results in JSON form.

=back

=head1 OPTIONS

L<Mojolicious::Plugin::GraphQL> supports the following options.

=head2 convert

Array-ref. First element is a classname-part, which will be prepended with
"L<GraphQL::Plugin::Convert>::". The other values will be passed
to that class's L<GraphQL::Plugin::Convert/to_graphql> method. The
returned hash-ref will be used to set options, particularly C<schema>,
and probably at least one of C<resolver> and C<root_value>.

=head2 endpoint

String. Defaults to C</graphql>.

=head2 schema

A L<GraphQL::Schema> object. As of 0.15, must be supplied.

=head2 root_value

An optional root value, passed to top-level resolvers.

=head2 resolver

An optional field resolver, replacing the GraphQL default.

=head2 handler

An optional route-handler, replacing the plugin's default - see example
above for possibilities.

It must return JSON-able Perl data in the GraphQL format, which is a hash
with at least one of a C<data> key and/or an C<errors> key.

If it throws an exception, that will be turned into a GraphQL-formatted
error.

If being used for a subscription, it will be called with a fourth
parameter as shown above. It is safe to not handle this if you are
content with GraphQL's defaults.

=head2 graphiql

Boolean controlling whether requesting the endpoint with C<Accept:
text/html> will return the GraphiQL user interface. Defaults to false.

  # Mojolicious::Lite
  plugin GraphQL => {schema => $schema, graphiql => 1};

=head2 keepalive

Defaults to 0, which means do not send. Otherwise will send a keep-alive
packet over websocket every specified number of seconds.

=head1 METHODS

L<Mojolicious::Plugin::GraphQL> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  my $route = $plugin->register(Mojolicious->new, {schema => $schema});

Register renderer in L<Mojolicious> application.

=head1 EXPORTS

Exportable is the function C<promise_code>, which returns a hash-ref
suitable for passing as the 8th argument to L<GraphQL::Execution/execute>.

=head1 SUBSCRIPTIONS

To use subscriptions within your web app, just insert this JavaScript:

  <script src="//unpkg.com/subscriptions-transport-ws@0.9.16/browser/client.js"></script>
  # ...
  const subscriptionsClient = new window.SubscriptionsTransportWs.SubscriptionClient(websocket_uri, {
    reconnect: true
  });
  subscriptionsClient.request({
    query: "subscription s($c: [String!]) {subscribe(channels: $c) {channel username dateTime message}}",
    variables: { c: channel },
  }).subscribe({
    next(payload) {
      var msg = payload.data.subscribe;
      console.log(msg.username + ' said', msg.message);
    },
    error: console.error,
  });

Note the use of parameterised queries, where you only need to change
the C<variables> parameter. The above is adapted from the sample app,
L<https://github.com/graphql-perl/sample-mojolicious>.

=head1 SEE ALSO

L<GraphQL>

L<GraphQL::Plugin::Convert>

L<https://github.com/apollographql/subscriptions-transport-ws#client-browser>
- Apollo documentation

=head1 AUTHOR

Ed J

Based heavily on L<Mojolicious::Plugin::PODRenderer>.

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;

__DATA__
@@ graphiql.html.ep
<!--
Copied from https://github.com/graphql/express-graphql/blob/master/src/renderGraphiQL.js
Converted to use the simple template to capture the CGI args
Added the apollo-link-ws stuff, marked with "ADDED"
-->
<!--
The request to this GraphQL server provided the header "Accept: text/html"
and as a result has been presented GraphiQL - an in-browser IDE for
exploring GraphQL.
If you wish to receive JSON, provide the header "Accept: application/json" or
add "&raw" to the end of the URL within a browser.
-->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>GraphiQL</title>
  <meta name="robots" content="noindex" />
  <style>
    html, body {
      height: 100%;
      margin: 0;
      overflow: hidden;
      width: 100%;
    }
  </style>
  <link href="//cdn.jsdelivr.net/npm/graphiql@<%= $graphiql_version %>/graphiql.css" rel="stylesheet" />
  <script src="//cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js"></script>
  <script crossorigin src="https://unpkg.com/react@16/umd/react.production.min.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@16/umd/react-dom.production.min.js"></script>
  <script src="//cdn.jsdelivr.net/npm/graphiql@<%= $graphiql_version %>/graphiql.min.js"></script>
  <% if ($subscriptionEndpoint) { %>
  <!-- ADDED -->
  <script src="//unpkg.com/subscriptions-transport-ws@0.9.16/browser/client.js"></script>
  <% } %>
</head>
<body>
  <script type="module">
    // Collect the URL parameters
    var parameters = {};
    window.location.search.substr(1).split('&').forEach(function (entry) {
      var eq = entry.indexOf('=');
      if (eq >= 0) {
        parameters[decodeURIComponent(entry.slice(0, eq))] =
          decodeURIComponent(entry.slice(eq + 1));
      }
    });
    // Produce a Location query string from a parameter object.
    function locationQuery(params) {
      return '?' + Object.keys(params).filter(function (key) {
        return Boolean(params[key]);
      }).map(function (key) {
        return encodeURIComponent(key) + '=' +
          encodeURIComponent(params[key]);
      }).join('&');
    }
    // Derive a fetch URL from the current URL, sans the GraphQL parameters.
    var graphqlParamNames = {
      query: true,
      variables: true,
      operationName: true
    };
    var otherParams = {};
    for (var k in parameters) {
      if (parameters.hasOwnProperty(k) && graphqlParamNames[k] !== true) {
        otherParams[k] = parameters[k];
      }
    }
    var fetchURL = locationQuery(otherParams);
    // Defines a GraphQL fetcher using the fetch API.
    function graphQLFetcher(graphQLParams) {
      return fetch(fetchURL, {
        method: 'post',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(graphQLParams),
        credentials: 'include',
      }).then(function (response) {
        return response.text();
      }).then(function (responseBody) {
        try {
          return JSON.parse(responseBody);
        } catch (error) {
          return responseBody;
        }
      });
    }
    // When the query and variables string is edited, update the URL bar so
    // that it can be easily shared.
    function onEditQuery(newQuery) {
      parameters.query = newQuery;
      updateURL();
    }
    function onEditVariables(newVariables) {
      parameters.variables = newVariables;
      updateURL();
    }
    function onEditOperationName(newOperationName) {
      parameters.operationName = newOperationName;
      updateURL();
    }
    function updateURL() {
      history.replaceState(null, null, locationQuery(parameters));
    }
    // this section ADDED
    <% if ($subscriptionEndpoint) { %>

    // this replaces the apollo GraphiQL-Subscriptions-Fetcher which is now incompatible with 0.6+ of subscriptions-transport-ws
    // based on matiasanaya PR to fix but with improvement to only look at definition of operation being executed
    import { parse } from "//unpkg.com/graphql@15.0.0/language/index.mjs";
    const subsGraphQLFetcher = (subscriptionsClient, fallbackFetcher) => {
      const hasSubscriptionOperation = (graphQlParams) => {
        const thisOperation = graphQlParams.operationName;
        const queryDoc = parse(graphQlParams.query);
        const opDefinitions = queryDoc.definitions.filter(
          x => x.kind === 'OperationDefinition'
        );
        const thisDefinition = opDefinitions.length == 1
          ? opDefinitions[0]
          : opDefinitions.filter(x => x.name.value === thisOperation)[0];
        return thisDefinition.operation === 'subscription';
      };
      let activeSubscription = false;
      return (graphQLParams) => {
        if (subscriptionsClient && activeSubscription) {
          subscriptionsClient.unsubscribeAll();
        }
        if (subscriptionsClient && hasSubscriptionOperation(graphQLParams)) {
          activeSubscription = true;
          return subscriptionsClient.request(graphQLParams);
        } else {
          return fallbackFetcher(graphQLParams);
        }
      };
    };

    var subscriptionEndpoint = <%== $subscriptionEndpoint %>;
    let subscriptionsClient = new window.SubscriptionsTransportWs.SubscriptionClient(subscriptionEndpoint, {
      lazy: true, // not in original
      reconnect: true
    });
    let myCustomFetcher = subsGraphQLFetcher(subscriptionsClient, graphQLFetcher);
    <% } else { %>
    let myCustomFetcher = graphQLFetcher;
    <% } %>
    // end ADDED
    // Render <GraphiQL /> into the body.
    ReactDOM.render(
      React.createElement(GraphiQL, {
        fetcher: myCustomFetcher, // ADDED changed from graphQLFetcher
        onEditQuery: onEditQuery,
        onEditVariables: onEditVariables,
        onEditOperationName: onEditOperationName,
        query: <%== $queryString %>,
        response: <%== $resultString %>,
        variables: <%== $variablesString %>,
        operationName: <%== $operationName %>,
      }),
      document.body
    );
  </script>
</body>
</html>
