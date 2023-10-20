use strict;
use warnings;
use Scalar::Util ();
use Carp ();

package Net::Correios::CEP;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

# DOC-PATCH: as chamadas à API de CEP exigem número de contrato.
sub enderecos {
    my ($self, %args) = @_;
    my $parent = $self->{parent};
    my $cep = $args{cep};
    $cep =~ s{[\s\.\-]+}{}g;
    Carp::croak("invalid CEP '$cep'") unless $cep =~ /\A[0-9]{8}\z/;

    my $res = $parent->make_request(
        'cartao',
        'GET',
        'cep/v2/enderecos/' . $cep,
    );
    return $parent->parse_response($res);
}

1;
