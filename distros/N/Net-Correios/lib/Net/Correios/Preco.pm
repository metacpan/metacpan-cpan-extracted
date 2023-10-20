use strict;
use warnings;
use Scalar::Util ();
use JSON ();

package Net::Correios::Preco;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub nacional {
    my ($self, @args) = @_;
    die 'nacional() espera uma sequencia de parametros' unless @args;

    my $args;
    if (ref $args[0] eq 'HASH') {
        $args = $self->_parse_nacional(@args);
    }
    else {
        $args = {@args};
    }

    my $parent = $self->{parent};

    my $res = $parent->make_request(
        'cartao',
        'POST',
        'preco/v1/nacional',
        { content => JSON::encode_json($args) }
    );
    return $parent->parse_response($res);
}

sub _parse_nacional {
    my ($self, @args) = @_;
    my $n = 1;
    my %req = ( idLote => 1, parametrosProduto => [] );

    # fazemos o pedido do token antes para garantirmos que temos
    # os dados de contrato e DR dentro do objeto. É no-op se já fez.
    $self->{parent}->access_token('cartao');

    foreach my $arg (@args) {
        my $tipo = $arg->{tipo} eq 'caixa'    ? 2
                 : $arg->{tipo} eq 'envelope' ? 1
                 : $arg->{tipo} eq 'rolo'     ? 3
                 : $arg->{tipo};

        my $cep_origem = $arg->{cep_origem};
        $cep_origem =~ s/[\.\-]+//g;
        my $cep_destino = $arg->{cep_destino};
        $cep_destino =~ s/[\.\-]+//g;

        foreach my $servico (split /\s*,\s*/ => $arg->{codigo}) {
            my $contrato = $arg->{contrato} || $self->{parent}{contrato};
            my $params = {
                ($contrato ? (nuContrato => $contrato) : ()),
                nuRequisicao => $n++,
                nuDR         => $arg->{dr} || $self->{parent}{dr},
                coProduto    => $servico,
                cepOrigem    => $cep_origem,
                cepDestino   => $cep_destino,
                psObjeto     => $arg->{peso},
                comprimento  => $arg->{comprimento},
                largura      => $arg->{largura},
                altura       => $arg->{altura},
                tpObjeto     => $tipo,
                ($arg->{data} ? (dtEvento => $arg->{data}) : ()),
            };
            if ($arg->{valor_declarado}) {
                $params->{vlDeclarado} = $arg->{valor_declarado};
                my $vd = $servico eq '03220' ? '019'
                       : $servico eq '03298' ? '064'
                       : '019';
                push @{$params->{servicosAdicionais}}, { coServAdicional => $vd };
            }
            if ($arg->{aviso_recebimento}) {
                push @{$params->{servicosAdicionais}}, { coServAdicional => '001' };
            }
            push @{$req{parametrosProduto}}, $params;
        }
    }
    return \%req;
}

1;
