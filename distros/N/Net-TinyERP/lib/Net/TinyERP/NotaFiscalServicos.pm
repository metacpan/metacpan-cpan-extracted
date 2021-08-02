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

sub pesquisar {
    my ($self, $params) = @_;
    die 'pesquisar() precisa de HASHREF como argumento'
        unless $params and ref $params and ref $params eq 'HASH';

    return $self->_post('https://api.tiny.com.br/api2/notas.servico.pesquisa.php', $params);
}

sub obter {
    my ($self, $id) = @_;
    die 'obter() precisa de argumento "id" numérico'
        unless $id && $id =~ /^\d+$/;

    return $self->_post('https://api.tiny.com.br/api2/nota.servico.obter.php', {
        id => $id,
    });
}

sub consultar {
    my ($self, $params) = @_;
    if (!ref $params) {
        $params = { id => $params, enviarEmail => 'N' };
    }
    die 'obter() precisa de argumento "id" numérico'
        unless ($params->{id} && $params->{id} =~ /\A\d+\z/s);

    return $self->_post('https://api.tiny.com.br/api2/nota.servico.consultar.php',
        $params,
    );
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
        dataInicial => '13/02/2018',
        dataFinal   => '03/11/2018',
    });

    foreach my $nf (@{ $res->{notas_servico} }) {
        say $nf->{nota_servico}{numero};
        say $nf->{nota_servico}{nome};
    }


Para mais informações sobre os parâmetros, consulte a 
L<< documentação do 'pesquisar' na API|https://www.tiny.com.br/ajuda/api/api2-notas-servico-pesquisar >>.

=head2 obter( $id )

Obtém dados sobre uma Nota de Serviços incluida no sistema do TinyERP
(via C<incluir()>).

    my $res = $tiny->nota_servicos->obter( 354040217 );

    if ($res->{status} eq 'OK') {
        my $nf = $res->{nota_servico};
        say $nf->{data_emissao};
        say $nf->{cliente}{cep};
        say $nf->{servico}{descricao};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'obter' na API|https://www.tiny.com.br/ajuda/api/api2-notas-servico-obter >>.

=head2 consultar( $id )

Parecida com C<obter()>, esse método consulta na prefeitura o andamento de uma
Nota de Serviços com situação 4 (Lote não processado). Note que essa consulta
é síncrona, então chamadas a essa API podem demorar e até mesmo gerar timeouts,
caso o serviço da sua prefeitura esteja com problemas de comunicação com a Tiny.

    my $res = $tiny->nota_servicos->consultar( 354040217 );

    if ($res->{status} eq 'OK') {
        my $nf = $res->{nota_servico};
        say $nf->{id};
        say $nf->{situacao};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'consultar' na API|https://www.tiny.com.br/ajuda/api/api2-notas-servico-consultar >>.


=head2 emitir( $id )

=head2 emitir( \%params )

Envia a Nota de Serviços selecionada à SEFAZ associada, criando uma NFSe
com valor fiscal.

    # equivalente a $tiny->nota_servicos->emitir({ id => '354040217' });
    my $res = $tiny->nota_fiscal->emitir( '354040217' );

    if ($res->{status} eq 'OK') {
        my $nf = $res->{nota_servico};
        say $nf->{situacao};
        say $nf->{link_impressao};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'emitir' na API|https://www.tiny.com.br/ajuda/api/api2-notas-servico-enviar >>.
Note que a Tiny chama de "enviar", mas para mantermos consistência com a
interface de NFe, mantemos o nome "emitir".

=head2 incluir( \%params )

Adiciona uma nova Nota de Serviços ao sistema do Tiny. Note que, após a
inclusão, você ainda precisa C<emitir()> a nota para que ela tenha valor
fiscal.

    my $res = $api->nota_servicos->incluir({
        data_emissao => '21/04/2019',
        cliente => {
            nome => 'Maria Silva',
            atualizar_cliente => 'N',
        },
        servico => {
            descricao => 'Assinatura do plano PRO',
            valor_servico => 29.95,
            codigo_lista_servico => '10.02.01',
        },
        descontar_iss_total => 'N',
    });

    if ($res->{status} eq 'OK') {
        say $res->{registros}[0]{registro}{status};
        say $res->{registros}[0]{registro}{id};
        say $res->{registros}[0]{registro}{numeroRPS};
    }

Para mais informações sobre os parâmetros, consulte a
L<< documentação do 'incluir' na API|https://www.tiny.com.br/ajuda/api/api2-notas-servico-incluir >>.

=head1 VEJA TAMBÉM

L<Net::TinyERP>


