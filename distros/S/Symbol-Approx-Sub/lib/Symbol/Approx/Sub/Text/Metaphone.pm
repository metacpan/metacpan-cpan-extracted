#
# Symbol::Approx::Sub::Text::Metaphone
#
# Transformer plugin for Symbol::Approx::Sub;
#
# Copyright (c) 2001, Magnum Solutions Ltd. All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Symbol::Approx::Sub::Text::Metaphone;

require 5.006_000;
use warnings;
use strict;

our ($VERSION, @ISA, $AUTOLOAD);

$VERSION = '3.1.2';

use Carp;
use Text::Metaphone;

=head1 NAME

Symbol::Approx::Sub::Text::Metaphone

=head1 SYNOPSIS

See L<Symbol::Approx::Sub>

=head1 METHODS

=head2 transform

Returns the array that it is passed with each element converted to its
metaphone equivalent.

=cut

sub transform {
  map { Metaphone($_) } @_;
}

1;
