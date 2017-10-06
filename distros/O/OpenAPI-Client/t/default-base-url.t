use Mojo::Base -strict;
use Mojo::JSON 'true';
use OpenAPI::Client;
use Test::More;

is(OpenAPI::Client->new('data://main/test.json')->base_url, 'http://localhost/', 'default base_url');

done_testing;

__DATA__
@@ test.json
{
  "swagger": "2.0",
  "info": {"version": "0.8", "title": "Test default base_url"},
  "paths": {}
}
