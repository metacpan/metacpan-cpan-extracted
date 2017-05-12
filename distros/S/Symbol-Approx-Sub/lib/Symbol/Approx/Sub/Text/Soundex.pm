#
# Symbol::Approx::Sub::Text::Soundex
#
# Transformer plugin for Symbol::Approx::Sub;
#
# Copyright (c) 2001, Magnum Solutions Ltd. All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Symbol::Approx::Sub::Text::Soundex;

require 5.006_000;
use strict;
use warnings;

our ($VERSION, @ISA, $AUTOLOAD);

$VERSION = '3.0.2';

use Carp;
use Text::Soundex;

=head1 NAME

Symbol::Approx::Sub::Text::Soundex

=head1 SYNOPSIS

See L<Symbol::Approx::Sub>

=head1 METHODS

=head2 transform

Returns the array it is passed with all values converted to their soundex
equivalent.

=cut

sub transform {
  map { soundex($_) } @_;
}

1;
