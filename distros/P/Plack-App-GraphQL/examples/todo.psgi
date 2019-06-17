use Plack::Builder;
use Plack::App::GraphQL;

my $schema = q|
  type Todo {
    task: String!
  }

  type Query {
    todos: [Todo]
  }

  type Mutation {
    add_todo(task: String!): Todo
  }
|;

my @data = (
  {task => 'Exercise!'},
  {task => 'Bulk Milk'},
  {task => 'Walk Dogs'},
);

my %root_value = (
  todos => sub {
    return \@data;
  },
  add_todo => sub {
    my ($args, $context, $info) = @_;
    $context->log->({level =>'debug', message => 'I am here.....'});
    push @data, $args;
    return $args;
  }
);

my $app = Plack::App::GraphQL
  ->new(
      schema => $schema, 
      root_value => \%root_value, 
      graphiql=>1,
      endpoint=>'/graphql')
  ->to_app;


builder {
  enable "SimpleLogger", level => "debug";
  $app;
};
