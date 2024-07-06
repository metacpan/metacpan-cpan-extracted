use strict;
use warnings;
use Scalar::Util ();
use JSON ();

package Net::Correios::Manifestacao;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub cadastra {
    my ($self, %args) = @_;
    die 'cadastra() espera um hash de parametros' unless keys %args;

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $request_data = {
        contrato => ($args{contrato} || $parent->{contrato}),
        cartao   => ($args{cartao} || $parent->{cartao}),
        #telefone => $args{telefone},
        pedidos  => [{
            codigoObjeto           => $args{codigo},
            emailResposta          => $args{email},
            nomeDestinatario       => $args{nome},
            codigoMotivoReclamacao => _traduz_motivo($args{motivo}),
            tipoEmbalagem          => _traduz_embalagem($args{embalagem}),
            tipoManifestacao       => ($args{ressarcimento} ? 'I' : 'R'),
        }],
    };

    my $res = $parent->make_request(
        'contrato',
        'POST',
        'pedido-informacao/v1/externo/pedidos/cadastra',
        { content => JSON::encode_json($request_data) }
    );
    return $parent->parse_response($res);
}

sub _traduz_embalagem {
    my ($codigo_orig) = @_;
    if ($codigo_orig) {
        my $codigo = lc $codigo_orig;
        my $len = length($codigo);
        if (substr('envelope', 0, $len) eq $codigo) {
            return 'E';
        }
        if (substr('caixa', 0, $len) eq $codigo) {
            return 'C';
        }
    }
    die "codigo $codigo_orig deve ser 'envelope' ou 'caixa'";
}

sub _traduz_motivo {
    my ($motivo) = @_;
    return $motivo if $motivo =~ /\A[0-9]+\z/;

    my %codigos = (
        violada                  => 133,
        danificada               => 134,
        entregue_com_atraso      => 135,
        devolvida                => 136,
        pedido_de_confirmacao    => 141,
        copia                    => 142,
        aviso_de_recebimento     => 148,
        nao_entregue             => 211,
        imagem_nao_disponivel    => 240,
        sem_tentativa_de_entrega => 1414,
    );

    return $codigos{$motivo} || die "motivo $motivo inexistente";
}

1;
