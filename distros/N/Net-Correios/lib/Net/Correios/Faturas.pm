use strict;
use warnings;
use Scalar::Util ();

package Net::Correios::Faturas;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub faturas {
    die 'nao implementado';
}

1;
