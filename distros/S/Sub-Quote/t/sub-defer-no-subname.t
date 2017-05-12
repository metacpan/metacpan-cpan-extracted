use strict;
use warnings;
use lib 't/lib';
use InlineModule
  'Sub::Name' => undef,
  'Sub::Util' => undef,
;
do './t/sub-defer.t';
die $@
  if $@;
