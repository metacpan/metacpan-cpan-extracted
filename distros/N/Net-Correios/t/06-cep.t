use strict;
use warnings;
use Test2::V0;
use utf8;

plan 8;

use Net::Correios;
use JSON ();

my $api = Net::Correios->new(
  username => 'foo',
  password => 'bar',
  cartao   => 1234,
  contrato => 4321
);
can_ok $api, 'cep';

ok my $cep = $api->cep, 'got the cep object';;
isa_ok $cep, 'Net::Correios::CEP';

can_ok $cep, 'enderecos';

# avoid making the token() request.
my $mocked_token = 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R';
$api->{token_cartao} = $mocked_token;

my $response_data = {
    bairro => 'Asa Norte',
    caixasPostais => [{
        nuFinal   => 9950,
        nuInicial => 9501
    }],
    cep              => '12345876',
    complemento      => 'Bloco A T�rreo',
    lado             => 'I',
    localidade       => 'Bras�lia',
    logradouro       => 'SBN Quadra 1',
    nome             => 'AC Central de Bras�lia',
    nomeLogradouro   => 'SBN Quadra 1',
    numeroFinal      => 1,
    numeroInicial    => 1,
    numeroLocalidade => 17781,
    siglaUnidade     => 'AC',
    tipoCEP          => 6,
    tipoLogradouro   => 'Quadra',
    uf               => 'DF'
};


my $mocked_ua = mock 'HTTP::Tiny' => (
  override => [
    request => sub {
      my ($self, $method, $url, $args) = @_;
      is $method, 'GET', 'proper cep method';
      is $url, 'https://api.correios.com.br/cep/v2/enderecos/12345876', 'proper cep url';
      is $args, {
        headers => { Authorization => 'Bearer ' . $mocked_token },
      }, 'proper header';
      return { success => 1, content => JSON::encode_json($response_data) };
    }
  ],
);

my $endereco = $cep->enderecos( cep => "  12.345-876  \t " );

is $endereco, $response_data, 'properly decoded data from API';
