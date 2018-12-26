#
# Symbol::Approx::Sub::String::Approx
#
# Matcher plugin for Symbol::Approx::Sub;
#
# Copyright (c) 2000, Magnum Solutions Ltd. All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Symbol::Approx::Sub::String::Approx;

require 5.006_000;
use warnings;
use strict;

our ($VERSION, @ISA, $AUTOLOAD);

$VERSION = '3.1.2';

use Carp;
use String::Approx 'amatch';

=head1 NAME

Symbol::Approx::Sub::String::Approx

=head1 SYNOPSIS

See L<Symbol::Approx::Sub>

=head1 METHODS

=head2 match

Passed a value and a list of values. Returns the values from  the list
which match the initial value using the C<amatch> method from
L<String::Approx>.

=cut

sub match {
  my ($sub, @subs) = @_;

  my @ret = grep { amatch($sub, $subs[$_]) } 0 .. $#subs;

  return @ret;
}

1;
