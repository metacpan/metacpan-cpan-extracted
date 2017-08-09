package Specio::Library::Coercions;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Declare;
use Specio::Library::Builtins;

declare(
    'IntC',
    parent => t('Int'),
);

coerce(
    t('IntC'),
    from  => t('ArrayRef'),
    using => sub { scalar @{ $_[0] } },
);

coerce(
    t('IntC'),
    from   => t('HashRef'),
    inline => sub {"scalar keys %{ $_[1] }"},
);

1;
