use strict;
use warnings;

use HTTP::Tiny;
use MIME::Base64 ();
use Carp         ();
use Scalar::Util ();
use JSON         ();

$Carp::Internal{ 'Net::Correios' }++;

package Net::Correios;

our $VERSION = '0.001';

my %libs = (
  token        => 'Token',
  cep          => 'CEP',
  sro          => 'SRO',
  preco        => 'Preco',
  prazo        => 'Prazo',
  empresas     => 'Empresas',
  prepostagens => 'Prepostagens',
  faturas      => 'Faturas',
  agencias     => 'Agencias',
);

# create lazy accessors.
foreach my $method (keys %libs) {
    $Carp::Internal{ 'Net::Correios::' . $libs{$method} }++;
    my $sub = sub {
        my ($self, %args) = @_;
        my $internal_key = 'endpoint_' . $method;
        if (!$self->{$internal_key}) {
            my $module = 'Net/Correios/' . $libs{$method} . '.pm';
            require $module;
            my $class = 'Net::Correios::' . $libs{$method};
            $self->{$internal_key} = $class->new( $self );
        }
        return $self->{$internal_key};
    };
    { no strict 'refs';
      *{"Net\::Correios\::$method"} = $sub;
    }
}

sub new {
    my ($class, %args) = @_;
    Carp::croak 'Net::Correios::new - "username" and "password" are required'
        unless $args{username} && $args{password};
    my $auth_basic = MIME::Base64::encode_base64($args{username} . ':' . $args{password}, '');
    return bless {
        contrato => $args{contrato},
        cartao => $args{cartao},
        sandbox => !!$args{sandbox},
        base_url => 'https://api' . (('hom')x!!$args{sandbox}) . '.correios.com.br/',
        auth_basic => $auth_basic,
        agent => HTTP::Tiny->new(
            default_headers => {
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
            },
            verify_SSL => 1,
            timeout => $args{timeout} || 5,
        ),
    }, $class;
}

sub is_sandbox { $_[0]->{sandbox} }

sub access_token {
    my ($self, $token_type) = @_;
    die 'token deve ser "cartao", "contrato" ou undef'
        if defined $token_type && $token_type ne 'cartao' && $token_type ne 'contrato';

    my $storage_key = 'token' . (defined $token_type ? '_' . $token_type : '');
    return $self->{$storage_key} if defined $self->{$storage_key};

    my $token_res = $self->token->autentica(
        (defined $token_type ? ($token_type => $self->{$token_type}) : ())
    );

    $self->{$storage_key} = $token_res->{token};
    if ($token_res->{cartaoPostagem} && (!$self->{cartao} || $self->{cartao} eq $token_res->{cartaoPostagem}{numero})) {
        $self->{dr} = $token_res->{cartaoPostagem}{dr};
        $self->{contrato} = $token_res->{cartaoPostagem}{contrato} if !$self->{contrato};
    }
    return $self->{$storage_key};
}

sub make_request {
    my ($self, $token_type, $method, $url, $args) = @_;
    $args = {} if !defined $args;
    $url = $self->{base_url} . $url;
    my $token = $self->access_token($token_type);
    $args->{headers}{Authorization} = 'Bearer ' . $token;
    my $res = $self->{agent}->request($method, $url, $args);
    return $res;
}

sub parse_response {
    my ($self, $res) = @_;
    if ($res->{success}) {
        my $data = JSON::decode_json($res->{content});
        return $data;
    }
    else {
        my $error = $res->{status} . ' ' . $res->{reason};
        $error .= ":\n" . $res->{content} if length $res->{content};
        $error .= "\n  " . $res->{url};
        Carp::croak($error);
    }
}

1;
__END__
=encoding utf-8

=head1 NAME

Net::Correios - acesse a API REST dos Correios

=head1 SYNOPSIS

    my $correios = Net::Correios->new(
        username => 'seu usuario',
        password => 'sua chave de API',
        contrato => 'seu número de contrato',
        cartao   => 'numero do seu cartao de postagem',
    );

    # Busca de CEP
    my $cep = $correios->cep->enderecos( cep => '01310-200' );
    say $cep->{logradouro};   # "Avenida Paulista"

    # Preços e Prazos
    my $params = {
        codigo            => '03220,03298',     # SEDEX e PAC
        cep_origem        => '01310-200',       # . e - ignorados
        cep_destino       => '20021-140',       # . e - ignorados
        tipo              => 'caixa',           # caixa, rolo ou envelope
        largura           => 16,                # cm
        altura            => 16,                # cm
        comprimento       => 16,                # cm
        peso              => 300,               # em gramas
        valor_declarado   => 100,               # (opcional) em BRL (reais)
        aviso_recebimento => true,              # booleano. padrão é falso.
    };

    my $fretes = $correios->preco->nacional($params);
    foreach my $frete (@$frete) {
        say $frete->{codigo} . ' custa R$' . $frete->{preco};
    }

    # você pode usar a mesma estrutura para preço e prazo (de nada):
    my $prazos = $correios->prazo->nacional($params);
    foreach my $prazo ($@prazos) {
        say "$prazo->{codigo} deve chegar até dia $prazo->{data_maxima}"
          . "($prazo->{dias} dias)";
    }

    # Rastreio de Objetos
    my $rastreio = $correios->sro->busca( 'YJ460348417BR', 'QP302718234BR' );
    say $rastreio->{YJ460348417BR}{situacao};
    foreach my $evento ($rastreio->{YJ460348417BR}{eventos}->@*) {
        say $evento->{descricao};
    }


=head1 DESCRIPTION

This module provides a way to query the Brazilian Postal Office (Correios) via
its REST API, regarding fees, estimated delivery times, etc. Since the main
audience for this module are Brazilian developers, the documentation is
provided in portuguese only. If you need help with this module but don't speak
portuguese, please contact the author.

=head1 DESCRIÇÃO

Este módulo oferece acesso à API REST dos Correios - também conhecida como
Correios Web Services ou CWS, ou mesmo "Correios API" - para consulta de
preços e prazos, CEPs, rastreamento de objetos, etc.

=head2 Requisitos

Para acessar a API REST dos Correios, você precisa:

1. Ter um contrato comercial ativo com os Correios;
2. Ter um cadastro no L<< Meu Correios|https://meucorreios.correios.com.br >>;
3. Acessar o site do Correios Web Services em L<https://cws.correios.com.br>,
fazer o login, clicar em "Gestão de Acesso a APIs" e depois em "Regerar Código".
Isso vai te dar uma chave/código de API para usar com este módulo.

Para usar esse módulo no ambiente de testes dos Correios, repita o passo 3
no site de homologação do CWS: https://cwshom.correios.com.br.

Procure seu contato nos Correios caso tenha dificuldade com qualquer um
desses passos.

=head1 CONSTRUTOR

=head2 new( %args )

    my $correios = Net::Correios->new(
        username => 'seu usuario',
        password => 'sua chave de API',
        contrato => 'seu número de contrato',
        cartao   => 'seu cartao de postagem',
    );

Cria um novo objeto para se comunicar com a API dos Correios. Este objeto pode
ser reaproveitado em todos os endpoints que seu programa usar, já que ele faz
automaticamente a gestão dos tokens de acesso à API.

=head1 ATRIBUTOS

=head2 is_sandbox

Retorna verdadeiro se o objeto está acessando o ambiente de
sandbox/homologação dos Correios, falso se estiver acessando o ambiente de
produção.

=head2 access_token( $tipo )

Retorna o token de acesso atual para o tipo solicitado. Você provavelmente
não precisa se preocupar com isso já que a criação e renovação dos tokens
de acesso são feitas automaticamente por este módulo e seus submódulos.

=head1 MÉTODOS

=head2 cep

Retorna um objeto L<Net::Correios::CEP> para busca de CEP e endereços.

=head2 sro

Retorna um objeto L<Net::Correios::SRO> para consulta de códigos de rastreio
e comprovantes de entrega de pacotes dos Correios.

=head2 preco

Retorna um objeto L<Net::Correios::Preco> para consulta de preços (tarifas)
para envios de encomendas/pacotes/postagens em diferentes tamanhos e formatos.

=head2 prazo

Retorna um objeto L<Net::Correios::Prazo> para consulta de prazos de entrega
para envios de encomendas.

=head2 token

Retorna um objeto L<Net::Correios::Token> para autenticação com a API.
Note que a autenticação e renovação de chaves é feita automaticamente
por este módulo, de modo que você provavelmente não precisará usar
este método diretamente.

=head2 empresas

TBD

=head2 prepostagens

TBD

=head2 faturas

TBD

=head2 agencias

TBD

=head1 VEJA TAMBÉM

L<< Correios Web Services|https://cws.correios.com.br/ >> (link externo oficial)
