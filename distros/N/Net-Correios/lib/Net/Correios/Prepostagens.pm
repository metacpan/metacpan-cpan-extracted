use strict;
use warnings;
use Scalar::Util ();

package Net::Correios::Prepostagens;

sub new {
    my ($class, $parent) = @_;
    Scalar::Util::weaken($parent);
    return bless { parent => $parent }, $class;
}

sub prepostagens {
    die 'nao implementado';
}

1;
