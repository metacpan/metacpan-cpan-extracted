#
# Module Parse::Eyapp.pm.
#
#
package Parse::Eyapp;
use 5.00600;
use strict;

BEGIN {
  unless (Parse::Eyapp::Driver->can('YYParse')) {
    our @ISA = qw(Parse::Eyapp::Output);
    require Parse::Eyapp::Output;
    # $VERSION is also in lib/Parse/Eyapp/Driver.pm
    our $VERSION = '1.182';
  }
}

1;

__END__

