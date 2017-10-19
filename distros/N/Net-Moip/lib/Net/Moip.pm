package Net::Moip;

use IO::Socket::SSL;
use MIME::Base64;
use Furl;

use String::CamelCase ();
use XML::SAX::Writer;
use XML::Generator::PerlData;

use Moo;

our $VERSION = 0.06;

has 'ua', is => 'ro', default => sub {
    Furl->new(
        agent         => "Net-Moip/$VERSION",
        timeout       => 15,
        max_redirects => 3,
        # <perigrin> "SSL Wants a read first" I think is suggesting you
        # haven't read OpenSSL a bedtime story in too long and perhaps
        # it's feeling neglected and lonely?
        # see also: https://metacpan.org/pod/IO::Socket::SSL#SNI-Support
        # https://metacpan.org/pod/Furl#FAQ
        # https://rt.cpan.org/Public/Bug/Display.html?id=86684
        ssl_opts => {
            SSL_verify_mode => SSL_VERIFY_PEER(),
        },
    );
};

has 'token', is => 'ro', required => 1;

has 'key', is => 'ro', required => 1;

has 'api_url', (
    is      => 'ro',
    writer  => '_set_api_url',
    default => 'https://www.moip.com.br/ws/alpha/EnviarInstrucao/Unica'
);

has 'sandbox', (
    is      => 'rw',
    default => 0,
    trigger => sub {
        my ($self, $sandbox) = @_;
        $self->_set_api_url( $sandbox
            ? 'https://desenvolvedor.moip.com.br/sandbox/ws/alpha/EnviarInstrucao/Unica'
            : 'https://www.moip.com.br/ws/alpha/EnviarInstrucao/Unica'
        );
    }
);

has 'decode_as', is => 'rw', default => undef;

sub pagamento_unico {
    my ($self, $args) = @_;

    my $xml  = $self->_gen_xml( $args );
    my $auth = 'Basic ' . MIME::Base64::encode( $self->token . ':' . $self->key, '');

    my $res = $self->ua->post(
        $self->api_url,
        [ 'Authorization' => $auth ],
        $xml
    );

    my %data = ( response => $res );
    if ($res->is_success) {
        my $c = $res->content;
        $data{id}     = $1 if $c =~ m{<ID>(.+?)</ID>};
        $data{status} = $1 if $c =~ m{<Status>(.+?)</Status>};
        $data{token}  = $1 if $c =~ m{<Token>(.+?)</Token>};

        while ($c =~ m{<Erro Codigo="(\d+)">(.+?)</Erro>}gs) {
            push @{$data{erros}}, { codigo => $1, mensagem => $2 };
        }
    }

    return \%data;
}

sub _gen_xml {
    my ($self, $args) = @_;
    my $xml;

    my $generator = XML::Generator::PerlData->new(
        Handler  => XML::SAX::Writer->new(
                        Output     => \$xml,
                        EncodeFrom => $self->decode_as,
                        EncodeTo   => 'iso-8859-1'
                    ),
        rootname => 'EnviarInstrucao',
        keymap   => {
            '*' => \&String::CamelCase::camelize,
            'url_notificacao' => 'URLNotificacao',
            'url_logo'        => 'URLLogo',
            'url_retorno'     => 'URLRetorno',
        },
        attrmap  => { InstrucaoUnica => ['TipoValidacao']  },
    );

    no autovivification;

    $args->{valores}{valor} = delete $args->{valor};

    if (my $acrescimo = delete $args->{acrescimo}) {
        $args->{valores}{acrescimo} = $acrescimo;
    }

    if (my $deducao = delete $args->{deducao}) {
        $args->{valores}{deducao} = $deducao;
    }

    if (my $cep = delete $args->{pagador}{endereco_cobranca}{cep}) {
        $args->{pagador}{endereco_cobranca}{CEP} = $cep;
    }

    my $xml_args  = { instrucao_unica => $args };

    $generator->parse( $xml_args );

    # FIXME: XML::Generator::PerlData does not know how to handle
    # elements with attributes *and* (leaf) data inside. And of course
    # Moip requires just that.
    if (exists $xml_args->{instrucao_unica}{pagador}{identidade}) {
        $xml =~ s{<Identidade>(\d+)</Identidade>}
                 {<Identidade Tipo="CPF">$1</Identidade>};
    }

    return $xml;
}

1;
__END__
=encoding utf8

=head1 NAME

Net::Moip - Interface com o gateway de pagamentos Moip

=head1 SYNOPSE

    use Net::Moip;

    my $gateway = Net::Moip->new(
        token => 'MY_MOIP_TOKEN',
        key   => 'MY_MOIP_KEY',
    );

    my $resposta = $gateway->pagamento_unico({
        razao           => 'Pagamento para a Loja X',
        tipo_validacao  => 'Transparente',
        valor           => 59.90,
        id_proprio      => 1,
        url_retorno     => 'http://exemplo.com/callback',
        url_notificacao => 'http://exemplo.com/notify',
        pagador => {
            id_pagador => 1,
            nome       => 'Cebolácio Júnior Menezes da Silva',
            email      => 'cebolinha@exemplo.com',
            endereco_cobranca => {
                logradouro    => 'Rua do Campinho',
                numero        => 9,
                bairro        => 'Limoeiro',
                cidade        => 'São Paulo',
                estado        => 'SP',
                pais          => 'BRA',
                cep           => '11111-111',
                telefone_fixo => '(11)93333-3333',
            },
        },
    });

    if ($resposta->{status} eq 'Sucesso') {
        print $resposta->{token};
        print $resposta->{id};
    }

=head2 Don't speak portuguese?

This module provides an interface to talk to the Moip API. Moip is a
popular brazilian online payments gateway. Since the target audience
for this distribution is mainly brazilian developers, the documentation
is provided in portuguese only. If you need any help or want to translate
it to your language, please send us some pull requests! :)

=head1 DESCRIÇÃO

Este módulo funciona como interface entre sua aplicação e a API do Moip.
Por enquanto B<apenas a versão 1 da API é suportada>, e apenas pagamentos
únicos.

Toda a API de pagamentos únicos é manipulada através de XMLs sem schema,
mas com estrutura documentada no site do Moip. Com o método
C<pagamento_unico> deste módulo você tem acesso direto ao endpoint de
pagamentos únicos do Moip e, enquanto a documentação deste módulo não
está completa, pode se guiar por lá.

A conversão entre tags XML e a estrutura de dados que você passa é
direta, exceto pelas tags C<Valor>, C<Acrescimo> e C<Deducao>, que
por questões práticas podem opcionalmente ficar no nível mais alto
da estrutura, como mostrado no exemplo da Sinopse.

Outra mudança é que as tags são escritas em I<snake_case> como é
padrão em Perl, em vez de I<CamelCase> como estão no XML do Moip. Em
outras palavras, a estrutura:

    <EnderecoCobranca>
        <Cidade>São Paulo</Cidade>
        <Estado>SP</Estado>
    </EnderecoCobranca>

deve ser passada na forma:

    endereco_cobranca => {
        cidade => 'São Paulo',
        estado => 'SP',
    }

=head2 Atenção com o encoding!

O Moip espera que seus dados estejam em I<iso-8859-1>. Este módulo
fará a coisa certa se seus dados estiverem no formato interno do Perl.
Se por acaso seus dados já estiverem codificados em I<utf-8> ou
qualquer outro formato, defina o atributo "L</"decode_as">" para o
formato desejado.

=head1 EXEMPLOS

=head2 Pagamentos únicos via checkout transparente

    my $resposta = $gateway->pagamento_unico({
        razao          => 'Pagamento para a Loja X',
        tipo_validacao => 'Transparente',
        valor          => 59.90,
        id_proprio     => 1,
        pagador => {
            id_pagador => 1,
            nome       => 'Cebolácio Júnior Menezes da Silva',
            email      => 'cebolinha@exemplo.com',
            endereco_cobranca => {
                logradouro    => 'Rua do Campinho',
                numero        => 9,
                bairro        => 'Limoeiro',
                cidade        => 'São Paulo',
                estado        => 'SP',
                pais          => 'BRA',
                cep           => '11111-111',
                telefone_fixo => '(11)93333-3333',
            },
        },
    });

=head2 decode_as

    my $gateway = Net::Moip->new(
        token     => '...',
        key       => '...',
        decode_as => 'utf-8',
    );

ou, a qualquer momento:

    $gateway->decode_as( 'utf-8' );

Por padrão, as strings da sua estrutura de dados não são decodificadas.
Utilize esse atributo para decodificá-las no formato desejado antes de
recodificá-las em 'iso-8859-1' e enviá-las ao Moip.

=head1 Compatibilidade e SSL/TLS

Como mencionado na descrição, o Net::Moip é compatível apenas com a
v1 da API do Moip.

Em meados de 2015, o
L<< Moip anunciou uma mudança de endpoints|https://moip.zendesk.com/hc/pt-br/articles/206767477-Certificado-Digital-com-tecnologia-SHA-256-Guia-de-Upgrade-do-Sistema >>,
de www.moip.com.br para api.moip.com.br. A fim de melhorar a segurança,
esse endpoint exigiria conexão com TLS 1.1 ou 1.2, usando certificado
digital assinado com SHA-256 e desativando completamente os protocolos
SSLv3 e TLS 1.0, considerados inseguros.

A versão 0.04 deste módulo foi lançada para acomodar essa mudança. Porém,
o Moip não cumpriu com seu próprio roadmap e o endpoint novo
nunca foi lançado. A versão 0.06 deste módulo restaura o uso do endpoint
antigo e as permissões liberais de SSL.

=head1 VEJA TAMBÉM

L<Business::CPI>, L<Business::CPI::Gateway::Moip>

L<https://desenvolvedor.moip.com.br>

=head1 LICENÇA E COPYRIGHT

Copyright 2014-2017 Breno G. de Oliveira C<< garu at cpan.org >>. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou modificá-lo sob os mesmos
termos que o Perl. Veja a licença L<perlartistic> para mais informações.

=head1 DISCLAIMER

PORQUE ESTE SOFTWARE É LICENCIADO LIVRE DE QUALQUER CUSTO, NÃO HÁ GARANTIA ALGUMA
PARA ELE EM TODA A EXTENSÃO PERMITIDA PELA LEI. ESTE SOFTWARE É OFERECIDO "COMO ESTÁ"
SEM QUALQUER GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA. TODO O RISCO RELACIONADO
À QUALIDADE, DESEMPENHO E COMPORTAMENTO DESTE SOFTWARE É DE QUEM O UTILIZAR.
