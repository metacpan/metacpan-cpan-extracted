package Mojolicious::Plugin::GraphQL;
# ABSTRACT: a plugin for adding GraphQL route handlers
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json to_json);
use GraphQL::Execution qw(execute);
use GraphQL::Type::Library -all;
use Module::Runtime qw(require_module);
use Mojo::Promise;
use Exporter 'import';

our $VERSION = '0.11';
our @EXPORT_OK = qw(promise_code);

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
  # currently only instance methods. not wasteful at all.
  resolve => sub { Mojo::Promise->new->resolve(@_) },
  reject => sub { Mojo::Promise->new->reject(@_) },
};

my @DEFAULT_METHODS = qw(get post);
use constant EXECUTE => sub {
  my ($schema, $query, $root_value, $per_request, $variables, $operationName, $field_resolver) = @_;
  execute(
    $schema,
    $query,
    $root_value,
    $per_request,
    $variables,
    $operationName,
    $field_resolver,
    # promise code - not overridable
    promise_code(),
  );
};
sub make_code_closure {
  my ($schema, $root_value, $field_resolver) = @_;
  sub {
    my ($c, $body, $execute) = @_;
    $execute->(
      $schema,
      $body->{query},
      $root_value,
      $c->req->headers,
      $body->{variables},
      $body->{operationName},
      $field_resolver,
    );
  };
}

sub _safe_serialize {
  my $data = shift or return 'undefined';
  my $json = to_json($data);
  $json =~ s#/#\\/#g;
  return $json;
}

sub register {
  my ($self, $app, $conf) = @_;
  if ($conf->{convert}) {
    my ($class, @values) = @{ $conf->{convert} };
    $class = "GraphQL::Plugin::Convert::$class";
    require_module $class;
    my $converted = $class->to_graphql(@values);
    @{$conf}{keys %$converted} = values %$converted;
  }
  die "Need schema or handler\n" if !grep $conf->{$_}, qw(schema handler);
  my $endpoint = $conf->{endpoint} || '/graphql';
  my $handler = $conf->{handler} || make_code_closure(
    map $conf->{$_}, qw(schema root_value resolver)
  );
  my $ajax_route = sub {
    my ($c) = @_;
    if (
      $conf->{graphiql} and
      # not as ignores Firefox-sent multi-accept: $c->accepts('', 'html') and
      ($c->req->headers->header('Accept')//'') =~ /^text\/html\b/ and
      !defined $c->req->query_params->param('raw')
    ) {
      return $c->render(
        template => 'graphiql',
        layout => undef,
        title            => 'GraphiQL',
        graphiql_version => 'latest',
        queryString      => _safe_serialize( $c->req->query_params->param('query') ),
        operationName    => _safe_serialize( $c->req->query_params->param('operationName') ),
        resultString     => _safe_serialize( $c->req->query_params->param('result') ),
        variablesString  => _safe_serialize( $c->req->query_params->param('variables') ),
      );
    }
    my $data;
    my $body = eval { decode_json($c->req->body) };
    $data = eval { $handler->($c, $body, EXECUTE()) } if !$@;
    $data = { errors => [ { message => $@ } ] } if $@;
    return $data->then(sub { $c->render(json => shift) }) if is_Promise($data);
    $c->render(json => $data);
  };
  push @{$app->renderer->classes}, __PACKAGE__
    unless grep $_ eq __PACKAGE__, @{$app->renderer->classes};
  $app->routes->any(\@DEFAULT_METHODS => $endpoint => $ajax_route);
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
  plugin GraphQL => {handler => sub {
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

=head1 DESCRIPTION

This plugin allows you to easily define a route handler implementing a
GraphQL endpoint.

As of version 0.09, it will supply the necessary C<promise_code>
parameter to L<GraphQL::Execution/execute>. This means your resolvers
can (and indeed should) return Promise objects to function
asynchronously. Notice not necessarily "Promises/A+" - all that's needed
is a two-arg C<then> to work fine with GraphQL.

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

A L<GraphQL::Schema> object. If not supplied, your C<handler> will need
to be a closure that will pass a schema on to GraphQL.

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

=head2 graphiql

Boolean controlling whether requesting the endpoint with C<Accept:
text/html> will return the GraphiQL user interface. Defaults to false.

  # Mojolicious::Lite
  plugin GraphQL => {schema => $schema, graphiql => 1};

=head1 METHODS

L<Mojolicious::Plugin::GraphQL> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  my $route = $plugin->register(Mojolicious->new, {schema => $schema});

Register renderer in L<Mojolicious> application.

=head1 EXPORTS

Exportable is the function C<promise_code>, which returns a hash-ref
suitable for passing as the 8th argument to L<GraphQL::Execution/execute>.

=head1 SEE ALSO

L<GraphQL>

L<GraphQL::Plugin::Convert>

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
  <script src="//cdn.jsdelivr.net/react/15.4.2/react.min.js"></script>
  <script src="//cdn.jsdelivr.net/react/15.4.2/react-dom.min.js"></script>
  <script src="//cdn.jsdelivr.net/npm/graphiql@<%= $graphiql_version %>/graphiql.min.js"></script>
</head>
<body>
  <script>
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
    // Render <GraphiQL /> into the body.
    ReactDOM.render(
      React.createElement(GraphiQL, {
        fetcher: graphQLFetcher,
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
