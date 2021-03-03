package MySubMeta::Parameters;
use strict;
use warnings;
use parent qw(Sub::Meta::Parameters);

use MySubMeta::Param;

# override
sub param_class { 'MySubMeta::Param' }

1;
