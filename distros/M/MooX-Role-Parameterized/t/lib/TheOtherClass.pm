package TheOtherClass;
use strict;
use warnings;

use Moo;
use MooX::Role::Parameterized::With TheParameterizedRole =>
  { attribute => 'bam', method => 'zzz' };

1;
