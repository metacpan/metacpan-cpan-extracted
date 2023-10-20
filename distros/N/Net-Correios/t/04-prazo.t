use strict;
use warnings;
use Test2::V0;
use JSON ();

plan 14;

use Net::Correios;

my $api = Net::Correios->new(
  username => 'foo',
  password => 'bar',
  cartao   => 1234,
  contrato => 4321
);
can_ok $api, 'prazo';

ok my $prazo = $api->prazo, 'got the prazo object';;
isa_ok $prazo, 'Net::Correios::Prazo';

can_ok $prazo, 'nacional';

# avoid making the token() request.
my $mocked_token = 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R';
$api->{token_cartao} = $mocked_token;

my $expected_request = {
    idLote => "1",
    parametrosPrazo => [{
      coProduto          => '03220',
      nuRequisicao       => "1",
      cepOrigem          => '11111111',
      cepDestino         => '22222222',
    },
    {
      coProduto          => '03298',
      nuRequisicao       => "2",
      cepOrigem          => '11111111',
      cepDestino         => '22222222',
    }]
};

# in reality the server would include two hashrefs in this arrayref response,
# because we asked for 2. But we are not testing the server here, just our code,
# so we simplify.
my $response_data = [{
    coProduto         => '03220',
    nuRequisicao      => 1,
    dataMaxima        =>'2023-09-22T23:58:00',
    entregaDomiciliar => 'S',
    entregaSabado     => 'N',
    nuRequisicao      => 1,
    prazoEntrega      => 1
}];


my $mocked_ua = mock 'HTTP::Tiny' => (
  override => [
    request => sub {
      my ($self, $method, $url, $args) = @_;
      is $method, 'POST', 'proper prazo method';
      is $url, 'https://api.correios.com.br/prazo/v1/nacional', 'proper prazo url';
      like $args, {
        headers => { Authorization => 'Bearer ' . $mocked_token },
        content => qr/\{.+\}/,
      }, 'proper header and some body';

      is JSON::decode_json($args->{content}), $expected_request, 'proper request body';
      return { success => 1, content => JSON::encode_json($response_data) };
    }
  ],
);

my $fretes = $prazo->nacional({
    codigo            => '03220,03298',
    cep_origem        => '11111-111',
    cep_destino       => '22.222-222',
    # the rest (from "preco" api) in not required,
    #  but we keep here to make sure it's ignored.
    tipo              => 'caixa',
    largura           => 16,
    altura            => 16,
    comprimento       => 16,
    peso              => 300,
    valor_declarado   => 100,
    aviso_recebimento => 1,
});

my $expanded_response = [{
  %{$response_data->[0]},
  data_maxima => '2023-09-22',
  codigo      => $response_data->[0]{coProduto},
  dias        => $response_data->[0]{prazoEntrega},
}];
is $fretes, $expanded_response, 'properly decoded data from API';

# we'll now request only one.
pop @{$expected_request->{parametrosPrazo}};

$fretes = $prazo->nacional(
    idLote => "1",
    parametrosPrazo => [{
      coProduto    => '03220', # SEDEX com contrato
      nuRequisicao => "1",
      cepOrigem    => '11111111',
      cepDestino   => '22222222',
    }]
);

is $fretes, $expanded_response, 'properly decoded second data from API';
