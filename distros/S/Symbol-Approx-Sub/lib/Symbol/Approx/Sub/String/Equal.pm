#
# Symbol::Approx::Sub::String::Equal
#
# Matcher plugin for Symbol::Approx::Sub;
#
# Copyright (c) 2000, Magnum Solutions Ltd. All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Symbol::Approx::Sub::String::Equal;

require 5.006_000;
use strict;
use warnings;

our ($VERSION, @ISA, $AUTOLOAD);

$VERSION = '3.0.2';

use Carp;

=head1 NAME

Symbol::Approx::Sub::String::Equal

=head1 SYNOPSIS

See L<Symbol::Approx::Sub>

=head1 METHODS

=head2 match

Passed a value and a list of values. Returns the values from the list
which equal (by string comparison) the initial value.

=cut

sub match {
  my ($sub, @subs) = @_;

  my @ret = grep { $sub eq $subs[$_] } 0 .. $#subs;

  return @ret;
}

1;
