use strict;
use warnings;
use Scalar::Util ();

package Net::Correios::Empresas;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub contratos {
    my ($self, %args) = @_;
    die 'cnpj obrigatorio' unless $args{cnpj};
    $args{cnpj} =~ s/[^0-9]+//g;
    die 'cnpj invalido' unless $args{cnpj};

    my $parent = $self->{parent};

# DOC-PATCH: as chamadas à API de contrato exigem número de contrato.
    my $res = $parent->make_request(
        'contrato',
        'GET',
        'meucontrato/v1/empresas/' . $args{cnpj} . '/contratos',
        {}
    );
    return $parent->parse_response($res);
}

sub servicos {
    my ($self, %args) = @_;
    die 'cnpj obrigatorio' unless $args{cnpj};
    $args{cnpj} =~ s/[^0-9]+//g;
    die 'cnpj invalido' unless $args{cnpj};

    my $parent = $self->{parent};
    my $contrato = $args{contrato} // $parent->{contrato};
    die 'contrato obrigatorio' unless $contrato;

# DOC-PATCH: as chamadas à API de contrato exigem número de contrato.
    my $res = $parent->make_request(
        'contrato',
        'GET',
        'meucontrato/v1/empresas/' . $args{cnpj} . '/contratos/' . $contrato . '/servicos' . ($args{servico} ? '/' . $args{servico} : ''),
        {}
    );
    return $parent->parse_response($res);
}


1;
