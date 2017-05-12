#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 1 }

ok (eval { require PAR::Dist; 1 });

__END__
