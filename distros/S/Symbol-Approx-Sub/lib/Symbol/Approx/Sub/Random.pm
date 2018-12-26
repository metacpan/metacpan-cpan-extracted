#
# Symbol::Approx::Sub::String::Equal
#
# Chooser plugin for Symbol::Approx::Sub;
#
# Copyright (c) 2000, Magnum Solutions Ltd. All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Symbol::Approx::Sub::Random;

require 5.006_000;
use strict;
use warnings;

our ($VERSION, @ISA, $AUTOLOAD);

$VERSION = '3.1.2';

use Carp;

=head1 NAME

Symbol::Approx::Sub::Random

=head1 SYNOPSIS

See L<Symbol::Approx::Sub>

=head1 METHODS

=head2 choose

Returns a random index into the array which it is passed.

=cut

sub choose {
  rand @_;
}

1;
