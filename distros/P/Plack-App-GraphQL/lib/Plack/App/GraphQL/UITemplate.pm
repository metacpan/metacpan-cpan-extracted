package Plack::App::GraphQL::UITemplate;

use Moo;
use Plack::Util;

has tt => (
  is => 'ro',
  required => 1,
  builder => '_build_tt',
  handles => {
    tt_process => 'process',
  }
);

  sub _build_tt {
    return Plack::Util::load_class('Template::Tiny')->new();
  }

has template => (
  is => 'ro',
  required => 1,
  builder => '_build_template',
);

  sub _build_template {
    $/ = undef;
    return my $data = <DATA>;
  }

has json_encoder => (
  is => 'ro',
  required => 1,
  handles => {
    json_encode => 'encode',
  },
);

sub safe_serialize {
  my ($self, $data) = @_;
  if($data) {
    my $json = $self->json_encode($data);
    $json =~ s#/#\\/#g;
    return $json;
  } else {
    return 'undefined';
  }
}

sub process {
  my ($self, $req) = @_;
  my $query = $req->query_parameters;
  my %args = $self->args_from_query($query);
  return my $body = $self->process_args(%args);
}

sub args_from_query {
  my ($self, $query) = @_;
  return my %args = (
    graphiql_version => 'latest',
    queryString      => $self->safe_serialize( $query->{'query'} ),
    operationName    => $self->safe_serialize( $query->{'operationName'} ),
    resultString     => $self->safe_serialize( $query->{'result'} ),
    variablesString  => $self->safe_serialize( $query->{'variables'} ),    
  );
}

sub process_args {
  my ($self, %args) = @_;
  my $input = $self->template;
  $self->tt_process(\$input, \%args, \my $output);
  return $output;
}

1;

=head1 NAME
 
Plack::App::GraphQL::UITemplate - Template and processing for the GraphQL UI

=head1 SYNOPSIS
 
  There's nothing really for end users here.  Its just refactored into its own
  package for code organization purposes.

=head1 DESCRIPTION

This is a package used to prepare and return an HTML response when you have the
'ui' flag enabled (probably for development) and the client requests an HTML
response.  This is based on L<https://github.com/graphql/graphiql>

Feel free to make your own improved development / query interface and put it on
CPAN!

=head1 AUTHOR
 
John Napiorkowski

=head1 SEE ALSO
 
L<Plack::App::GraphQL>
 
=cut

__DATA__

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
  <link href="//cdn.jsdelivr.net/npm/graphiql@[% graphiql_version %]/graphiql.css" rel="stylesheet" />
  <script src="//cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js"></script>
  <script src="//cdn.jsdelivr.net/react/15.4.2/react.min.js"></script>
  <script src="//cdn.jsdelivr.net/react/15.4.2/react-dom.min.js"></script>
  <script src="//cdn.jsdelivr.net/npm/graphiql@[% graphiql_version %]/graphiql.min.js"></script>
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
        query: [% queryString %],
        response: [% resultString %],
        variables: [% variablesString %],
        operationName: [% operationName %],
      }),
      document.body
    );
  </script>
</body>
</html>

