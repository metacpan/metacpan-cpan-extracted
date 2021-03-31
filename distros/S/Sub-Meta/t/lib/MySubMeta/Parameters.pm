package MySubMeta::Parameters;
use strict;
use warnings;
use parent qw(Sub::Meta::Parameters);

use MySubMeta::Param;

# override
sub param_class { return 'MySubMeta::Param' }

1;
