package Monitoring::Sneck::Checks::not_a_check;

# Loads, but is not a Monitoring::Sneck::Checks::base.

use strict;
use warnings;

sub new { return bless( {}, $_[0] ) }

1;
