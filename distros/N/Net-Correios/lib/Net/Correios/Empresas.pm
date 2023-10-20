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
    my $parent = $self->{parent};
    die 'cnpj obrigatorio' unless $args{cnpj};
    $args{cnpj} =~ s/[^0-9]+//g;
    die 'cnpj invalido' unless $args{cnpj};

# DOC-PATCH: as chamadas à API de contrato exigem número de contrato.
    my $token = $parent->access_token;
    if (!$token) {
        my $token_res = $parent->token->autentica();
        $token = $parent->access_token($token_res->{token});
    }

    my $res = $parent->{agent}->request(
        'GET',
        $parent->{base_url} . '/v1/empresas/' . $args{cnpj} . '/contratos',
        {
            headers => { 'Authorization' => 'Bearer ' . $token },
        }
    );
    return $parent->parse_response($res);

}

1;
