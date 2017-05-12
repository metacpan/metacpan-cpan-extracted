=pod

=head1 NAME

t/000-use.t - Net::Prober test suite

=head1 DESCRIPTION

Basic sanity check

=cut

use strict;
use warnings;

use Test::More tests => 1;
use Net::Prober;

ok(1, "Loaded");

