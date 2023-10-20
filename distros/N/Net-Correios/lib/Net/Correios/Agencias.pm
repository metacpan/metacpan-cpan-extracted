use strict;
use warnings;
use Scalar::Util ();

package Net::Correios::Agencias;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub agencias {
    die 'nao implementado';
}

1;
