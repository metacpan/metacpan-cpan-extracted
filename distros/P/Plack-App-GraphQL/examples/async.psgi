use Plack::App::GraphQL;
use Future;
use Safe::Isa;

my $schema = q|
  type Query {
    hello: String
  }
|;

my %root_value = (
  hello => sub {
    my ($args, $context, $info) = @_;
    return Future->done('world!!')
  }
);

my $promise_code = +{
  then => sub {
    my ($future, $code) = @_;
    return $future->then(sub {
      my @normalized_results = $code->(@_);
      return Future->wrap(@normalized_results);
    });
  },
  all => sub {
    my @futures = map {
      my $future = $_->$_can('then') ? $_ : Future->done($_);
      $future->transform(done => sub { [@_] }); 
    } @_;
    Future->needs_all(@futures);
  },
  resolve => sub { Future->done(@_) },
  reject => sub { Future->fail(@_) },
};

return my $app = Plack::App::GraphQL
  ->new(
      schema => $schema, 
      root_value => \%root_value,
      promise_code => $promise_code,
      graphiql=>1,
      endpoint=>'/graphql')
  ->to_app;
