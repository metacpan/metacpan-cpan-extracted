package PDL::Finance::Talib;

use strict;
use warnings;

our $VERSION = "0.009";

sub import {
  eval 'use PDL::Finance::TA;'
}

1;

=head1 NAME

PDL::Finance::Talib - DEPRECATED (use PDL::Finance::TA instead)

=head1 SEE ALSO

L<PDL::Finance::TA>

=cut
