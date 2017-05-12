#!/usr/bin/perl

package Net::SixXS::Diag;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moose::Role;

requires 'debug';

no Moose::Role;

1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::Diag> - a role for displaying diagnostic messages

=head1 SYNOPSIS

  use Moose;

  with 'Net::SixXS::Diag';

  sub debug($ $) {
      my ($self, $s) = @_;

      warn ref($self)." diagnostics: $s\n";
  }

=head1 DESCRIPTION

The C<Net::SixXS::Diag> role guarantees the existence of a single
method named C<debug>.  It is supposed to take a single parameter -
a text string - and, well, do something with it.  The exact details of
what is done to the string and whether anything is done with it at all
are left to the classes implementing the role.

=head1 METHODS

As noted above, C<Net::SixXS::Diag> expects a single method called
C<debug>; the C<Net::SixXS> class hierarchy will call that method with
a single text string as a parameter.

=head1 SEE ALSO

L<Net::SixXS::Diag::None>, L<Net::SixXS::Diag::MainDebug>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

