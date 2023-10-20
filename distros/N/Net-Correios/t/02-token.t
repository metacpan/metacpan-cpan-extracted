use strict;
use warnings;

use Test2::V0;
use JSON ();

use Net::Correios;

plan 8;

my $api = Net::Correios->new( username => 'foo', password => 'bar' );
can_ok $api, 'token';

ok my $token = $api->token, 'got the token object';;
isa_ok $token, 'Net::Correios::Token';

can_ok $token, 'autentica';
my $response_data = {
    ambiente   => 'PRODUCAO',
    cnpj       => '11111111000111',
    emissao    => '2023-09-21T14:40:03',
    expiraEm   => '2023-09-22T14:40:03',
    id         => 'myusername',
    ip         => '192.168.1.1,192.168.1.2',
    perfil     => 'PJ',
    token      => 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R',
    zoneOffset => '-03:00',
};

my $mocked_ua = mock 'HTTP::Tiny' => (
  override => [
    request => sub {
      my ($self, $method, $url, $args) = @_;
      is $method, 'POST', 'proper token method';
      is $url, 'https://api.correios.com.br/token/v1/autentica', 'proper token url';
      is $args, { headers => { Authorization => 'Basic Zm9vOmJhcg==' } }, 'proper header';
      return { success => 1, content => JSON::encode_json($response_data) };
    }
  ],
);

my $res = $token->autentica();
is $res, $response_data, 'properly decoded data from API';
