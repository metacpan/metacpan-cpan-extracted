package MySubMeta;
use strict;
use warnings;
use parent qw(Sub::Meta);

use MySubMeta::Parameters;
use MySubMeta::Returns;

# override
sub parameters_class { 'MySubMeta::Parameters' }
sub returns_class { 'MySubMeta::Returns' }

1;
