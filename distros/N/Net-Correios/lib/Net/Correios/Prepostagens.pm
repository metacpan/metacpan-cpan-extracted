use strict;
use warnings;
use Scalar::Util ();

package Net::Correios::Prepostagens;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub criar {
    my ($self, $args) = @_;
    die 'criar() espera uma sequencia de parametros' unless $args;

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $request_data = $args;

    my $res = $parent->make_request(
        'cartao',
        'POST',
        'prepostagem/v1/prepostagens',
        { content => JSON::encode_json($request_data) }
    );
    return $parent->parse_response($res);
}

sub emitir_rotulo {
    my ($self, $params) = @_;
    die 'emitir_rotulo() espera uma sequencia de parametros' unless $params;
    die 'emitir_rotulo() precisa de hashref com pelo menos o id' unless $params->{id};

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $request_data = {
        tipoRotulo => $params->{tipo_rotulo} // 'P', # P(adrao) ou R(eduzido)
        formatoRotulo => $params->{formato_rotulo} // 'ET', # ET(iqueta) ou EV(elope)
        imprimeRemetente => $params->{imprime_remetente} // 'N', # S(im) ou N(ao)
        idsPrePostagem => [$params->{id}],
        layoutImpressao => $params->{layout_impressao} // 'PADRAO', # PADRAO, LINEAR_100_150, LINEAR_100_80, LINEAR_A4. Default PADRAO.
    };

    my $res = $parent->make_request(
        'cartao',
        'POST',
        'prepostagem/v1/prepostagens/rotulo/assincrono/pdf',
        { content => JSON::encode_json($request_data) }
    );
    return $parent->parse_response($res);
}

sub obter_rotulo_emitido {
    my ($self, $id) = @_;
    die 'obter_rotulo_emitido() espera um rotulo' unless $id;

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $res = $parent->make_request(
        'cartao',
        'GET',
        'prepostagem/v1/prepostagens/rotulo/download/assincrono/' . $id,
    );
    return $parent->parse_response($res);
}


sub cancelar {
    my ($self, $id) = @_;
    die 'cancelar() espera um rotulo' unless $id;

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $res = $parent->make_request(
        'cartao',
        'DELETE',
        'prepostagem/v1/prepostagens/' . $id,
        {}
    );
    return $parent->parse_response($res);
}

sub consulta {
    my ($self, $rastreio) = @_;

    my $parent = $self->{parent};

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $parent->access_token('cartao');

    my $res = $parent->make_request(
        'cartao',
        'GET',
        'prepostagem/v1/prepostagens/postada?codigoObjeto=' . $rastreio
    );
    return $parent->parse_response($res);
}




1;
