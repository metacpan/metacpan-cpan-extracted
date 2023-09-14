use v5.012;
use strict;
use warnings;

package issing::XS;

use Missing::XS ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';
sub import { goto \&Missing::XS::import }

1;
