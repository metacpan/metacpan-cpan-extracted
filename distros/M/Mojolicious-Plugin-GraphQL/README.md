# NAME

Mojolicious::Plugin::GraphQL - a plugin for adding GraphQL route handlers

# SYNOPSIS

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

    # for Mojolicious substitute "plugin" with $app->plugin(...
    # Mojolicious::Lite (with endpoint under "/graphql")
    plugin GraphQL => {schema => $schema};

    # OR, equivalently:
    plugin GraphQL => {handler => sub {
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

    # OR, with bespoke user-lookup and caching:
    plugin GraphQL => {handler => sub {
      my ($c, $body, $execute) = @_;
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
      ));
    };

    # With GraphiQL, on /graphql
    plugin GraphQL => {schema => $schema, graphiql => 1};

# DESCRIPTION

This plugin allows you to easily define a route handler implementing a
GraphQL endpoint.

The route handler code will be compiled to behave like the following:

- Passes to the [GraphQL](https://metacpan.org/pod/GraphQL) execute, possibly via your supplied handler,
the given schema, `$root_value` and `$field_resolver`.
- The action built matches POST / GET requests.
- Returns GraphQL results in JSON form.

# OPTIONS

[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) supports the following options.

## endpoint

String. Defaults to `/graphql`.

## schema

A [GraphQL::Schema](https://metacpan.org/pod/GraphQL::Schema) object. If not supplied, your `handler` will need
to be a closure that will pass a schema on to GraphQL.

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

## graphiql

Boolean controlling whether requesting the endpoint with `Accept:
text/html` will return the GraphiQL user interface. Defaults to false.

    # Mojolicious::Lite
    plugin GraphQL => {schema => $schema, graphiql => 1};

# METHODS

[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    my $route = $plugin->register(Mojolicious->new, {schema => $schema});

Register renderer in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[GraphQL](https://metacpan.org/pod/GraphQL)

# AUTHOR

Ed J

Based heavily on [Mojolicious::Plugin::PODRenderer](https://metacpan.org/pod/Mojolicious::Plugin::PODRenderer).

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
