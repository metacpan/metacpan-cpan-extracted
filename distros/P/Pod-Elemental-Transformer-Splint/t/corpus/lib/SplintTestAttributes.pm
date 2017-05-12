use 5.10.1;
use strict;
use warnings;

package SplintTestAttributes;

use Moose;
use MooseX::AttributeDocumented;

has testattr => (
    is => 'ro',
    isa => 'Int',
    documentation => 'A fine attribute',
    documentation_order => 2,
    documentation_alts => {
        1 => 'a good number',
        2 => 'also a good number',
    },
);

1;

__END__

=pod

=encoding utf-8

:splint classname SplintTestAttributes

:splint attributes
