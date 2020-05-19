# NAME

Mojolicious::Plugin::GraphQL - a plugin for adding GraphQL route handlers

# SYNOPSIS

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

# DESCRIPTION

This plugin allows you to easily define a route handler implementing a
GraphQL endpoint, including a websocket for subscriptions following
Apollo's `subscriptions-transport-ws` protocol.

As of version 0.09, it will supply the necessary `promise_code`
parameter to ["execute" in GraphQL::Execution](https://metacpan.org/pod/GraphQL::Execution#execute). This means your resolvers
can (and indeed should) return Promise objects to function
asynchronously. As of 0.15 these must be "Promises/A+" as subscriptions
require `resolve` and `reject` methods.

The route handler code will be compiled to behave like the following:

- Passes to the [GraphQL](https://metacpan.org/pod/GraphQL) execute, possibly via your supplied handler,
the given schema, `$root_value` and `$field_resolver`. Note as above
that the wrapper used in this plugin will supply the hash-ref matching
["PromiseCode" in GraphQL::Type::Library](https://metacpan.org/pod/GraphQL::Type::Library#PromiseCode).
- The action built matches POST / GET requests.
- Returns GraphQL results in JSON form.

# OPTIONS

[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) supports the following options.

## convert

Array-ref. First element is a classname-part, which will be prepended with
"[GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert)::". The other values will be passed
to that class's ["to\_graphql" in GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert#to_graphql) method. The
returned hash-ref will be used to set options, particularly `schema`,
and probably at least one of `resolver` and `root_value`.

## endpoint

String. Defaults to `/graphql`.

## schema

A [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) object. As of 0.15, must be supplied.

## root\_value

An optional root value, passed to top-level resolvers.

## resolver

An optional field resolver, replacing the GraphQL default.

## handler

An optional route-handler, replacing the plugin's default - see example
above for possibilities.

It must return JSON-able Perl data in the GraphQL format, which is a hash
with at least one of a `data` key and/or an `errors` key.

If it throws an exception, that will be turned into a GraphQL-formatted
error.

If being used for a subscription, it will be called with a fourth
parameter as shown above. It is safe to not handle this if you are
content with GraphQL's defaults.

## graphiql

Boolean controlling whether requesting the endpoint with `Accept:
text/html` will return the GraphiQL user interface. Defaults to false.

    # Mojolicious::Lite
    plugin GraphQL => {schema => $schema, graphiql => 1};

## keepalive

Defaults to 0, which means do not send. Otherwise will send a keep-alive
packet over websocket every specified number of seconds.

# METHODS

[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    my $route = $plugin->register(Mojolicious->new, {schema => $schema});

Register renderer in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# EXPORTS

Exportable is the function `promise_code`, which returns a hash-ref
suitable for passing as the 8th argument to ["execute" in GraphQL::Execution](https://metacpan.org/pod/GraphQL::Execution#execute).

# SEE ALSO

[GraphQL](https://metacpan.org/pod/GraphQL)

[GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL::Plugin::Convert)

# AUTHOR

Ed J

Based heavily on [Mojolicious::Plugin::PODRenderer](https://metacpan.org/pod/Mojolicious::Plugin::PODRenderer).

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
