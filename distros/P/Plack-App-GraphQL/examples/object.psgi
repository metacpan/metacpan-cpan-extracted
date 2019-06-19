use Plack::App::GraphQL;

{
  package Local::TodoList;

  my @data = (
    {task => 'Exercise!'},
    {task => 'Bulk Milk'},
    {task => 'Walk Dogs'},
  );

  sub new {
    my ($class, %args) = @_;
    return bless \@data, $class;
  }

  sub todos {
    my ($self, $args, $context) = @_;
    my @tasks = @$self;
    return \@tasks;
  }

  sub add_todo {
    my ($self, $args) = @_;
    push @{$self}, $args;
    return $args;
  }
}

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


return my $app = Plack::App::GraphQL
  ->new(
      schema => $schema, 
      root_value => Local::TodoList->new, 
      graphiql=>1,
      endpoint=>'/graphql')
  ->to_app;

