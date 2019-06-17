use Plack::App::GraphQL;

return my $app = Plack::App::GraphQL
  ->new(
      endpoint => '/graphql',
      convert => ['Test'],
      graphiql => 1 )
  ->to_app;
