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
can_ok $api, 'preco';

ok my $preco = $api->preco, 'got the preco object';;
isa_ok $preco, 'Net::Correios::Preco';

can_ok $preco, 'nacional';

# avoid making the token() request.
my $mocked_token = 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R';
$api->{token_cartao} = $mocked_token;
$api->{dr} = 11;

my $expected_request = {
    idLote => "1",
    parametrosProduto => [{
      coProduto          => '03220',
      nuRequisicao       => "1",
      nuContrato         => '4321',
      nuDR               => 11,
      cepOrigem          => '11111111',
      psObjeto           => 300,
      tpObjeto           => 2,
      comprimento        => 16,
      largura            => 16,
      altura             => 16,
      servicosAdicionais => [{coServAdicional => "019"}, {coServAdicional => "001"}],
      vlDeclarado        => 100,
      cepDestino         => '22222222',
    },
    {
      coProduto          => '03298',
      nuRequisicao       => "2",
      nuContrato         => '4321',
      nuDR               => 11,
      cepOrigem          => '11111111',
      psObjeto           => 300,
      tpObjeto           => 2,
      comprimento        => 16,
      largura            => 16,
      altura             => 16,
      servicosAdicionais => [{coServAdicional => "064"}, {coServAdicional => "001"}],
      vlDeclarado        => 100,
      cepDestino         => '22222222',
    }]
};

# in reality the server would include two hashrefs in this arrayref response,
# because we asked for 2. But we are not testing the server here, just our code,
# so we simplify.
my $response_data = [{
    coProduto                 => '03220',
    inPesoCubico              => 'N',
    nuRequisicao              => 1,
    pcBase                    => '10,68',
    pcBaseGeral               => '30,98',
    pcFaixa                   => '30,98',
    pcFaixaVariacao           => '26,39',
    pcFinal                   => '34,55',
    pcProduto                 => '26,39',
    pcReferencia              => '26,39',
    pcTotalServicosAdicionais => '8,16',
    peAdValorem               => '0,0100',
    peVariacao                => '0,1480',
    psCobrado                 => 300,
    qtAdicional               => 0,
    servicoAdicional          => [
        {
            coServAdicional    => '019',
            pcServicoAdicional => '0,76',
            tpServAdicional    => 'V',
        },
        {
            coServAdicional    => '001',
            pcServicoAdicional => '7,40',
            tpServAdicional    => 'A',
        }
    ],
    vlBaseCalculoImposto       =>'34,55',
    vlSeguroAutomatico         =>'24,50',
    vlTotalDescVariacao        =>'4,59',
}];


my $mocked_ua = mock 'HTTP::Tiny' => (
  override => [
    request => sub {
      my ($self, $method, $url, $args) = @_;
      is $method, 'POST', 'proper preco method';
      is $url, 'https://api.correios.com.br/preco/v1/nacional', 'proper preco url';
      like $args, {
        headers => { Authorization => 'Bearer ' . $mocked_token },
        content => qr/\{.+\}/,
      }, 'proper header and some body';

      is JSON::decode_json($args->{content}), $expected_request, 'proper request body';
      return { success => 1, content => JSON::encode_json($response_data) };
    }
  ],
);

my $fretes = $preco->nacional({
    codigo            => '03220,03298',
    cep_origem        => '11111-111',
    cep_destino       => '22.222-222',
    tipo              => 'caixa',
    largura           => 16,
    altura            => 16,
    comprimento       => 16,
    peso              => 300,
    valor_declarado   => 100,
    aviso_recebimento => 1,
});


is $fretes, $response_data, 'properly decoded data from API';

# we'll now request only one.
pop @{$expected_request->{parametrosProduto}};

$fretes = $preco->nacional(
    idLote => "1",
    parametrosProduto => [{
      coProduto    => '03220', # SEDEX com contrato
      nuRequisicao => "1",
      nuContrato   => '4321',
      nuDR         => 11,
      cepOrigem    => '11111111',
      psObjeto     => 300,
      tpObjeto     => 2,
      comprimento  => 16,
      largura      => 16,
      altura       => 16,
      servicosAdicionais => [{coServAdicional => "019"}, {"coServAdicional" => "001"}],
      vlDeclarado  => 100,
      cepDestino   => '22222222',
    }]
);

is $fretes, $response_data, 'properly decoded second data from API';
