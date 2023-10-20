use strict;
use warnings;
use Scalar::Util ();
use JSON ();

package Net::Correios::Token;

sub new {
    my ($class, $parent) = @_;

    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub autentica {
    my ($self, %args) = @_;
    my $parent = $self->{parent};

    my $endpoint_url = $parent->{base_url} . 'token/v1/autentica';
    my $json_body;
    # TODO: precisamos entender quais endpoints funcionam com quais tokens.
    # muito provavelmente precisaremos de ambos ao mesmo tempo.
    if ($args{contrato}) {
        $endpoint_url .= '/contrato';
        $json_body = JSON::encode_json({ numero => $args{contrato} });
    }
    elsif ($args{cartao}) {
        $endpoint_url .= '/cartaopostagem';
        $json_body = JSON::encode_json({ numero => $args{cartao} });
    }

    my $res = $parent->{agent}->request(
        'POST',
        $endpoint_url,
        {
            headers => { 'Authorization' => 'Basic ' . $parent->{auth_basic} },
            (defined $json_body? (content => $json_body) : ()),
        },
    );
    return $parent->parse_response($res);
}

1;
