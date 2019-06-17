use Plack::App::GraphQL;
use HTTP::Request::Common;
use Test::Most;
use Plack::Test;
use JSON::MaybeXS;

ok my $schema = q|
  type Query {
    hello: String
  }
|;

ok my %root_value = (
  hello => sub {
    return 'Hello World!'
  }
);

ok my $app = Plack::App::GraphQL
  ->new(
      schema => $schema, 
      root_value => \%root_value)
  ->to_app;

ok my $test = Plack::Test->create($app);

ok my $res = $test->request(POST '/',
  Accept => 'application/json', 
  Content => '{"query":"{hello}"}');

ok my $data = decode_json($res->content);
is $data->{data}{hello}, 'Hello World!';

done_testing;
