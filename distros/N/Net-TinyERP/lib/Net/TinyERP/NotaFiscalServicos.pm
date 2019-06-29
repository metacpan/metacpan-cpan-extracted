package Net::TinyERP::NotaFiscalServicos;
use strict;
use warnings;
use IO::Socket::SSL;
use Scalar::Util ();
use Furl;
use JSON::MaybeXS qw( decode_json encode_json );

sub new {
    my ($class, $parent) = @_;
    my $token = \$parent->{token};
    Scalar::Util::weaken($token);
    bless {
        parent_token => $token,
        ua => Furl->new(
            timeout => 30,
            ssl_opts => {
                SSL_verify_mode => SSL_VERIFY_PEER(),
            },
        ),
    }, $class;
}

sub _post {
    my ($self, $url, $params) = @_;
    my $res = $self->{ua}->post($url, undef, {
        token   => ${$self->{parent_token}},
        formato => 'json',
        %$params,
    });

    if ($res->is_success) {
        my $content = decode_json($res->decoded_content);
        return $content->{retorno};
    }
    else {
        return;
    }
}

# FIXME
sub pesquisar {
    my ($self, $params) = @_;
    die 'pesquisar() precisa de HASHREF como argumento'
        unless $params and ref $params and ref $params eq 'HASH';

    return $self->_post('https://api.tiny.com.br/api2/notas.fiscais.pesquisa.php', $params);
}

# FIXME
sub obter {
    my ($self, $id) = @_;
    die 'obter() precisa de argumento "id" numérico'
        unless $id && $id =~ /^\d+$/;

    return $self->_post('https://api.tiny.com.br/api2/nota.fiscal.obter.php', {
        id => $id,
    });
}

sub obter_xml {
    die 'obter_xml() nao foi implementado';
}

# FIXME:
sub obter_link {
    my ($self, $id) = @_;
    die 'obter_link() precisa de argumento "id" numérico'
        unless $id && $id =~ /^\d+$/;

    return $self->_post( 'https://api.tiny.com.br/api2/nota.fiscal.obter.link.php', {
        id => $id,
    });
}

sub incluir {
    my ($self, $params) = @_;
    die 'incluir() precisa de HASHREF como argumento'
        unless $params and ref $params and ref $params eq 'HASH';

    return $self->_post( 'https://api.tiny.com.br/api2/nota.servico.incluir.php', {
        nota => encode_json({ nota_servico => $params }),
    });
}


sub emitir {
    my ($self, $params) = @_;
    if (!ref $params) {
        $params = { id => $params, enviarEmail => 'N' };
    }
    die 'emitir() precisa de numero de identificação da nota de serviço no Tiny'
        unless ($params->{id} && $params->{id} =~ /\A\d+\z/s);

    return $self->_post( 'https://api.tiny.com.br/api2/nota.servico.enviar.php',
        $params
    );
}

1;
__END__
=encoding utf8

=head1 NAME

Net::TinyERP::NotaFiscalServicos - Nota Fiscal de Serviços Eletrônica (NFSe) via TinyERP

=head1 MÉTODOS

=head2 pesquisar( \%params )

    my $res = $tiny->nota_servicos->pesquisar({
        dataInicial => '13/02/2016',
        dataFinal   => '03/11/2016',
    });

    foreach my $nf (@{ $res->{notas_fiscais} }) {
        say $nf->{nota_fiscal}{descricao_situacao};
        say $nf->{nota_fiscal}{nome};
    }


Para mais informações sobre os parâmetros, consulte a 
L<< documentação do 'pesquisar' na API|https://tiny.com.br/help?p=api2-notas-fiscais-pesquisar >>.

=head2 obter( $id )

Obtém dados sobre uma Nota Fiscal incluida no sistema do TinyERP
(via C<incluir()>).

    my $res = $tiny->nota_fiscal->obter( 354040217 );

    if ($res->{status} eq 'OK') {
        my $nf = $res->{nota_fiscal};
        say $nf->{base_icms};
        say $nf->{data_emissao}
        say $nf->{cliente}{cep};
        say $nf->{itens}[0]{item}{descricao};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'obter' na API|https://tiny.com.br/help?p=api2-notas-fiscais-obter >>.

=head2 obter_xml( $id )

B<Não implementado>. Sinta-se livre para nos mandar um Pull Request! :)

=head2 obter_link( $id )

Obtém link para DANFE em formato PDF de uma Nota Fiscal já emitida
(via C<emitir()>). Esse PDF deverá ser impresso e enviado em
conjunto com a mercadoria.

    my $res = $tiny->nota_fiscal->obter_link( '354040217' );
   
    if ($res->{status} eq 'OK') {
        say $res->{link_nfe};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'obter link' na API|https://tiny.com.br/help?p=api2-notas-fiscais-obter-link >>.

=head2 emitir( $id )

=head2 emitir( \%params )

Envia a Nota Fiscal selecionada à SEFAZ associada, criando uma NFe
com valor fiscal.

    # equivalente a $tiny->nota_fiscal->emitir({ id => '354040217' });
    my $res = $tiny->nota_fiscal->emitir( '354040217' );

    if ($res->{status} eq 'OK') {
        my $nf = $res->{nota_fiscal};
        say $nf->{descricao_situacao};
        say $nf->{link_acesso};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'emitir' na API|https://tiny.com.br/help?p=api2-notas-fiscais-emitir >>.

=head2 incluir( \%params )

Adiciona uma nova Nota Fiscal ao sistema do Tiny. Note que, após a inclusão, você
ainda precisa C<emitir()> a nota para que ela tenha valor fiscal.

    my $res = $api->nota_fiscal->incluir({
        tipo                    => 'S',
        natureza_operacao       => 'venda',
        data_emissao            => '13/01/2016',
        frete_por_conta         => 'R',
        valor_despesas          => 3.50,
        numero_pedido_ecommerce => '9876',

        cliente => {
            nome              => 'José da Silva',
            tipo_pessoa       => 'F',
            cpf_cnpj          => '11111111111',
            endereco          => 'Rua Exemplo',
            numero            => '34',
            complemento       => '503',
            bairro            => 'Bairro Exemplo',
            cep               => '12345678',
            cidade            => 'Cidade Exemplo',
            uf                => 'SP',
            pais              => 'BRASIL',
            atualizar_cliente => 'N',
        },

        itens => [
            { item => {
                codigo         => '1234',
                descricao      => 'Produto Legal',
                unidade        => 'UN',
                quantidade     => 1.00,
                valor_unitario => 9.99,
                tipo           => 'P',
                origem         => 0,
                ncm            => '1111',
            }},
            { item => {
                codigo         => '5678',
                descricao      => 'Outro Produto',
                unidade        => 'UN',
                quantidade     => 3.00,
                valor_unitario => 13.50,
                tipo           => 'P',
                origem         => 0,
                ncm            => '2222',
            }},
        ],
    });

    if ($res->{status} eq 'OK') {
        say $res->{registros}{registro}{id};
        say $res->{registros}{registro}{status};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'incluir' na API|https://tiny.com.br/help?p=api2-notas-fiscais-incluir >>.

=head1 VEJA TAMBÉM

L<Net::TinyERP>


