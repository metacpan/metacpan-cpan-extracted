use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;

BEGIN { $ENV{TEST_MOJO_GA_BATCH_GET_DIR} = path(path(__FILE__)->dirname, 'ga-batch-files')->to_abs }
use Mojo::GoogleAnalytics;

my $ga = Mojo::GoogleAnalytics->new(
  client_email => 'test@example.com',
  client_id    => '100000000000000000000',
  private_key  => sample_private_key(),
);

my $query = {
  viewId     => 'ga:123456789',
  dateRanges => [{startDate => '7daysAgo', endDate => '1daysAgo'}],
  dimensions => [{name => 'ga:country'}, {name => 'ga:browser'}],
  metrics    => [{expression => 'ga:pageviews'}, {expression => 'ga:sessions'}],
  orderBys   => [{fieldName => 'ga:pageviews', sortOrder => 'DESCENDING'}],
  pageSize   => 2,
};

eval { $ga->batch_get($query) };
like $@, qr{Could not read dummy response file}, 'batch_get without dummy response';

$query->{viewId} = 'ga:100000000';
my $report = $ga->batch_get($query);
is $report->count,      3,            'batch_get: count';
is $report->page_token, 'some-token', 'batch_get: page_token';
ok !$report->error, 'batch_get: error';

$report = undef;
$ga->batch_get_p($query)->then(sub { $report = shift })->wait;
is $report->count, 3, 'batch_get_p: count';
ok !$report->error, 'batch_get_p: error' or diag explain $report->error;

my $err = 'not called';
$ga->{token_uri} = '/no/such/route';
$ga->authorization({});
$ga->authorize_p->catch(sub { $err = shift })->wait;
like $err, qr{Not Found}, 'authorize_p: failed';

done_testing;

sub sample_private_key {
  return <<'HERE';
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA4qiw8PWs7PpnnC2BUEoDRcwXF8pq8XT1/3Hc3cuUJwX/otNe
fr/Bomr3dtM0ERLN3DrepCXvuzEU5FcJVDUB3sI+pFtjjLBXD/zJmuL3Afg91J9p
79+Dm+43cR6wuKywVJx5DJIdswF6oQDDzhwu89d2V5x02aXB9LqdXkPwiO0eR5s/
xHXgASl+hqDdVL9hLod3iGa9nV7cElCbcl8UVXNPJnQAfaiKazF+hCdl/syrIh0K
CZ5opggsTJibo8qFXBmG4PkT5YbhHE11wYKILwZFSvZ9iddRPQK3CtgFiBnXbVwU
5t67tn9pMizHgypgsfBoeoyBrpTuc4egSCpjsQIDAQABAoIBAF2sU/wxvHbwAhQE
pnXVMMcO0thtOodxzBz3JM2xThhWnVDgxCPkAhWq2X0NSm5n9BY5ajwyxYH6heTc
p6lagtxaMONiNaE2W7TqxzMw696vhnYyL+kH2e9+owEoKucXz4QYatqsJIQPb2vM
0h+DfFAgUvNgYNZ2b9NBsLn9oBImDfYueHyqpRGTdX5urEVtmQz029zaC+jFc7BK
Y6qBRSTwFwnVgE+Td8UgdrO3JQ/0Iwk/lkphnhls/BYvdNC5O8oEppozNVmMV8jm
61K+agOh1KD8ky60iQFjo3VdFpUjI+W0+sYiYpDb4+Z9OLOTK/5J2EBAGim9siyd
gHspx+UCgYEA9+t5Rs95hG9Q+6mXn95hYduPoxdFCIFhbGl6GBIGLyHUdD8vmgwP
dHo7Y0hnK0NyXfue0iFBYD94/fuUe7GvcXib93heJlvPx9ykEZoq9DZnhPFBlgIE
SGeD8hClazcr9O99Fmg3e7NyTuVou+CIublWWlFyN36iamP3a08pChsCgYEA6gvT
pi/ZkYI1JZqxXsTwzAsR1VBwYslZoicwGNjRzhvuqmqwNvK17dnSQfIrsC2VnG2E
UbE5EIAWbibdoL4hWUpPx5Tl096OjC3qBR6okAxbVtVEY7Rmv7J9RwriXhtD1DYp
eBvo3eQonApFkfI8Lr2kuKGIgwzkZ72QLXsKJiMCgYBZXBCci0/bglwIObqjLv6e
zQra2BpT1H6PGv2dC3IbLvBq7hN0TQCNFTmusXwuReNFKNq4FrB/xqEPusxsQUFh
fv2Il2QoI1OjUE364jy1RZ7Odj8TmKp+hoEykPluybYYVPIbT3kgJy/+bAXyIh5m
Av2zFEQ86HIWMu4NSb0bHQKBgETEZNOXi52tXGBIK4Vk6DuLpRnAIMVl0+hJC2DB
lCOzIVUBM/VxKvNP5O9rcFq7ihIEO7SlFdc7S1viH4xzUOkjZH2Hyl+OLOQTOYd3
kp+AgfXpg8an4ujAUP7mu8xaxns7zsNzr+BCgYwXmIlhWz2Aiz2UeL/IsfOpRwuV
801xAoGADQB84MJe/X8xSUZQzpn2KP/yZ7C517qDJjComGe3mjVxTIT5XAaa1tLy
T4mvpSeYDJkBD8Hxr3fB1YNDWNbgwrNPGZnUTBNhxIsNLPnV8WySiW57LqVXlggH
vjFmyDdU5Hh6ma4q+BeAqbXZSJz0cfkBcBLCSe2gIJ/QJ3YJVQI=
-----END RSA PRIVATE KEY-----
HERE
}
