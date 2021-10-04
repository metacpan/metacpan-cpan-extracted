use Mojo::Base -strict;
use OpenAPI::Client;
use Test::More;

subtest default => sub {
  my $client = OpenAPI::Client->new('data://main/test.json');
  isa_ok($client->base_url, 'Mojo::URL');
  is($client->base_url, 'http://localhost/', 'base_url');
};

subtest constructor => sub {
  my $client = OpenAPI::Client->new('data://main/test.json', base_url => 'https://example.com/v1/');
  isa_ok($client->base_url, 'Mojo::URL');
  is($client->base_url, 'https://example.com/v1/', 'base_url');

  $client = OpenAPI::Client->new('data://main/test.json', base_url => Mojo::URL->new('https://example.com/v1/'));
  isa_ok($client->base_url, 'Mojo::URL');
  is($client->base_url, 'https://example.com/v1/', 'base_url');
};

subtest attribute => sub {
  my $client = OpenAPI::Client->new('data://main/test.json');
  isa_ok($client->base_url, 'Mojo::URL');
  is($client->base_url, 'http://localhost/', 'base_url');

  $client->base_url->host('other.example.com')->path('/test');
  isa_ok($client->base_url, 'Mojo::URL');
  is($client->base_url, 'http://other.example.com/test', 'base_url');
};

done_testing;

__DATA__
@@ test.json
{
  "swagger": "2.0",
  "info": {"version": "0.8", "title": "Test default base_url"},
  "paths": {}
}
