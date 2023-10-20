use strict;
use warnings;
use Scalar::Util;
use JSON ();

package Net::Correios::Prazo;

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

# DOC-PATCH: as chamadas à API de prazo exigem número de cartao.
    my $raw = $parent->make_request(
        'cartao',
        'POST',
        'prazo/v1/nacional',
        { content => JSON::encode_json($args) }
    );
    my $res = $parent->parse_response($raw);
    foreach my $r (@$res) {
        $r->{codigo} = $r->{coProduto};
        $r->{dias} = $r->{prazoEntrega};
        my ($data, $hora) = split /T/, $r->{dataMaxima};
        $r->{data_maxima} = $data;
    }
    return $res;
}

sub _parse_nacional {
    my ($self, @args) = @_;
    my $n = 1;
    my %req = ( idLote => 1, parametrosPrazo => [] );

    foreach my $arg (@args) {
        my $cep_origem = $arg->{cep_origem};
        $cep_origem =~ s/[\.\-]+//g;
        my $cep_destino = $arg->{cep_destino};
        $cep_destino =~ s/[\.\-]+//g;

        foreach my $servico (split /\s*,\s*/ => $arg->{codigo}) {
            my $params = {
                nuRequisicao => $n++,
                coProduto    => $servico,
                cepOrigem    => $cep_origem,
                cepDestino   => $cep_destino,
                ($arg->{data} ? (dtEvento => $arg->{data}) : ()),
            };
            push @{$req{parametrosPrazo}}, $params;
        }
    }
    return \%req;
}

1;
