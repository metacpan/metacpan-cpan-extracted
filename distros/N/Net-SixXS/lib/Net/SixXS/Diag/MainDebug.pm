#!/usr/bin/perl

package Net::SixXS::Diag::MainDebug;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moose;

with 'Net::SixXS::Diag';

sub debug($ $)
{
	main::debug($_[1]);
}

1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::Diag::MainDebug> - relay diagnostic messages to a debug() routine

=head1 SYNOPSIS

  package main;

  use Net::SixXS;
  use Net::SixXS::Diag::MainDebug;

  Net::SixXS::diag(Net::SixXS::Diag::MainDebug->new());

  my $verbose;

  sub debug($) {
      say STDERR "Diag: $_[1]" if $verbose;
  }

=head1 DESCRIPTION

The C<Net::SixXS::Diag::MainDebug> class implements the L<Net::SixXS::Diag>
role by passing all messages to a method named C<debug()> in the C<main>
package, thus allowing the main program to decide whether and how to display
any diagnostic messages.

=head1 METHODS

The C<Net::SixXS::Diag::MainDebug> class implements the L<Net::SixXS::Diag>
role by supplying a single method named C<debug()> that forwards the message
to the main program's C<debug()> routine as described above.

=head1 SEE ALSO

L<Net::SixXS::Diag>, L<Net::SixXS::Diag::None>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

