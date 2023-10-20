use strict;
use warnings;
use Test2::V0;
use utf8;

plan 5;

use Net::Correios;

my $api = Net::Correios->new(
  username => 'foo',
  password => 'bar',
  cartao   => 1234,
  contrato => 4321
);

can_ok $api, 'sro';
ok my $sro = $api->sro, 'got the sro object';
isa_ok $sro, 'Net::Correios::SRO';

# avoid making the token() request.
my $mocked_token = 'thisISaMOCk3dT0k3N.weUSE1tf0RtESt1nGTheACtu4lOn3ISmUChbiGG3R';
$api->{token_cartao} = $mocked_token;

subtest 'objetos()' => sub {
    plan 5;
    can_ok $sro, 'objetos';    
    my $raw_response_data = {
      objetos => [
          {
              altura      => 6,
              codObjeto   => 'AA111111111BR',
              comprimento => 36,
              contrato    => '4321',
              dtPrevista  => '2023-03-30T20:59:59',
              eventos     => [
                  {
                      codigo     => 'BDE',
                      descricao  => 'Objeto entregue ao remetente',
                      dtHrCriado => '2023-03-27T14:40:30',
                      tipo       => 23,
                      unidade    => {
                          codSro  => '88888888',
                          endereco => {
                              cidade => 'COLOMBO',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  },
                  {
                      codigo     => 'OEC',
                      descricao  => 'Objeto saiu para entrega ao remetente',
                      dtHrCriado => '2023-03-27T09:54:53',
                      tipo       => '09',
                      unidade => {
                          endereco => {
                              bairro      => 'GUARAITUBA',
                              cep         => '88888888',
                              cidade      => 'COLOMBO',
                              complemento => 'QUILOMETRO 17',
                              logradouro  => 'ESTRADA DA RIBEIRA BR-476',
                              numero      => 318,
                              uf          => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  },
                  {
                      codigo     => 'RO',
                      descricao  => 'Objeto em tr�nsito - por favor aguarde',
                      dtHrCriado => '2023-03-25T20:42:11',
                      tipo       => '01',
                      unidade    => {
                          codSro => '22222222',
                          endereco => {
                              cidade => 'CURITIBA',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Tratamento'
                      },
                      unidadeDestino => {
                          endereco => {
                              cidade => 'COLOMBO',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  }
              ],
              formato       =>  'Pacote',
              largura       =>  26,
              modalidade    =>  'F',
              peso          =>  0.06,
              tipoPostal    =>  {
                  categoria => 'ENCOMENDA PAC',
                  descricao => 'ETIQUETA LOGICA PAC',
                  sigla     => 'QP'
              },
              valorDeclarado => 35.9
        },
        {
            codObjeto => 'BB222222222BR',
            mensagem  => 'SRO-020: Objeto n�o encontrado na base de dados dos Correios.',
        },
      ],
    };
    my $mocked_ua = mock 'HTTP::Tiny' => (
      override => [
        request => sub {
          my ($self, $method, $url, $args) = @_;
          is $method, 'GET', 'proper cep method';
          is $url, 'https://api.correios.com.br/srorastro/v1/objetos?codigosObjetos=AA111111111BR&codigosObjetos=BB222222222BR&resultado=U', 'proper sro url';
          is $args, {
            headers => { Authorization => 'Bearer ' . $mocked_token },
          }, 'proper header';
          return { success => 1, content => JSON::encode_json($raw_response_data) };
        },
      ],
    );

    my $res = $sro->objetos( objetos => ['AA111111111BR', 'BB222222222BR'] );
    is $res, $raw_response_data, 'properly decoded data from API';
};

subtest 'busca()' => sub {
    plan 5;
    can_ok $sro, 'busca';    
    my $raw_response_data = {
      objetos => [
          {
              altura      => 6,
              codObjeto   => 'AA111111111BR',
              comprimento => 36,
              contrato    => '4321',
              dtPrevista  => '2023-03-30T20:59:59',
              eventos     => [
                  {
                      codigo     => 'BDE',
                      descricao  => 'Objeto entregue ao remetente',
                      dtHrCriado => '2023-03-27T14:40:30',
                      tipo       => 23,
                      unidade    => {
                          codSro  => '88888888',
                          endereco => {
                              cidade => 'COLOMBO',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  },
                  {
                      codigo     => 'OEC',
                      descricao  => 'Objeto saiu para entrega ao remetente',
                      dtHrCriado => '2023-03-27T09:54:53',
                      tipo       => '09',
                      unidade => {
                          endereco => {
                              bairro      => 'GUARAITUBA',
                              cep         => '88888888',
                              cidade      => 'COLOMBO',
                              complemento => 'QUILOMETRO 17',
                              logradouro  => 'ESTRADA DA RIBEIRA BR-476',
                              numero      => 318,
                              uf          => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  },
                  {
                      codigo     => 'RO',
                      descricao  => 'Objeto em tr�nsito - por favor aguarde',
                      dtHrCriado => '2023-03-25T20:42:11',
                      tipo       => '01',
                      unidade    => {
                          codSro => '22222222',
                          endereco => {
                              cidade => 'CURITIBA',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Tratamento'
                      },
                      unidadeDestino => {
                          endereco => {
                              cidade => 'COLOMBO',
                              uf     => 'PR'
                          },
                          tipo => 'Unidade de Distribui��o'
                      }
                  }
              ],
              formato       =>  'Pacote',
              largura       =>  26,
              modalidade    =>  'F',
              peso          =>  0.06,
              tipoPostal    =>  {
                  categoria => 'ENCOMENDA PAC',
                  descricao => 'ETIQUETA LOGICA PAC',
                  sigla     => 'QP'
              },
              valorDeclarado => 35.9
        },
        {
            codObjeto => 'BB222222222BR',
            mensagem  => 'SRO-020: Objeto n�o encontrado na base de dados dos Correios.',
        },
      ],
    };

    my $parsed_response_data = {
      AA111111111BR => {
        altura      => 6,
        codObjeto   => 'AA111111111BR',
        comprimento => 36,
        contrato    => '4321',
        dtPrevista  => '2023-03-30T20:59:59',
        eventos     => [
            {
                codigo     => 'BDE',
                descricao  => 'Objeto entregue ao remetente',
                dtHrCriado => '2023-03-27T14:40:30',
                tipo       => 23,
                unidade    => {
                    codSro  => '88888888',
                    endereco => {
                        cidade => 'COLOMBO',
                        uf     => 'PR'
                    },
                    tipo => 'Unidade de Distribui��o'
                }
            },
            {
                codigo     => 'OEC',
                descricao  => 'Objeto saiu para entrega ao remetente',
                dtHrCriado => '2023-03-27T09:54:53',
                tipo       => '09',
                unidade => {
                    endereco => {
                        bairro      => 'GUARAITUBA',
                        cep         => '88888888',
                        cidade      => 'COLOMBO',
                        complemento => 'QUILOMETRO 17',
                        logradouro  => 'ESTRADA DA RIBEIRA BR-476',
                        numero      => 318,
                        uf          => 'PR'
                    },
                    tipo => 'Unidade de Distribui��o'
                }
            },
            {
                codigo     => 'RO',
                descricao  => 'Objeto em tr�nsito - por favor aguarde',
                dtHrCriado => '2023-03-25T20:42:11',
                tipo       => '01',
                unidade    => {
                    codSro => '22222222',
                    endereco => {
                        cidade => 'CURITIBA',
                        uf     => 'PR'
                    },
                    tipo => 'Unidade de Tratamento'
                },
                unidadeDestino => {
                    endereco => {
                        cidade => 'COLOMBO',
                        uf     => 'PR'
                    },
                    tipo => 'Unidade de Distribui��o'
                }
            }
        ],
        formato       =>  'Pacote',
        largura       =>  26,
        modalidade    =>  'F',
        peso          =>  0.06,
        situacao      =>  'devolvido',
        tipoPostal    =>  {
            categoria => 'ENCOMENDA PAC',
            descricao => 'ETIQUETA LOGICA PAC',
            sigla     => 'QP'
        },
        valorDeclarado => 35.9
      },
      BB222222222BR => {
            codObjeto => 'BB222222222BR',
            mensagem  => 'SRO-020: Objeto n�o encontrado na base de dados dos Correios.',
            situacao  => 'não encontrado'
      },
    };
    my $mocked_ua = mock 'HTTP::Tiny' => (
      override => [
        request => sub {
          my ($self, $method, $url, $args) = @_;
          is $method, 'GET', 'proper cep method';
          is $url, 'https://api.correios.com.br/srorastro/v1/objetos?codigosObjetos=AA111111111BR&codigosObjetos=BB222222222BR&resultado=T', 'proper sro url';
          is $args, {
            headers => { Authorization => 'Bearer ' . $mocked_token },
          }, 'proper header';
          return { success => 1, content => JSON::encode_json($raw_response_data) };
        },
      ],
    );

    my $res = $sro->busca( 'AA111111111BR', 'BB222222222BR' );
    is $res, $parsed_response_data, 'properly decoded data from API';
};
