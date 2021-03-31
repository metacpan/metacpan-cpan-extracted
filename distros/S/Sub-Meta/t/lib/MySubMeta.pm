package MySubMeta;
use strict;
use warnings;
use parent qw(Sub::Meta);

use MySubMeta::Parameters;
use MySubMeta::Returns;

# override
sub parameters_class { return 'MySubMeta::Parameters' }
sub returns_class { return 'MySubMeta::Returns' }

1;
