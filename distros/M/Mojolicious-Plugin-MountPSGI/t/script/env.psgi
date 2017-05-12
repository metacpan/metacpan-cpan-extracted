use Mojo::JSON;
my $app = sub {
  my $env = shift;
  return [200, ['Content-Type' => 'application/json'], [Mojo::JSON::encode_json($env)]];
}
