#!perl

use strict;
use warnings;
use PerlIO::code;

open my $in, '<', sub{ return uc scalar <> };

print while <$in>;
