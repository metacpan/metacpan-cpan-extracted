#!/usr/bin/perl

package Net::SixXS::Diag::None;

use v5.010;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.1.1");

use Moose;

with 'Net::SixXS::Diag';

sub debug($ $)
{
}

no Moose;

1;
__END__

=encoding utf-8

=head1 NAME

C<Net::SixXS::Diag::None> - swallow diagnostic messages whole

=head1 SYNOPSIS

  package main;

  use Net::SixXS::TIC::Client;
  use Net::SixXS::Diag::None;

  my $c = Net::SixXS::TIC::Client->new(...,
      diag => Net::SixXS::Diag::None->new());

=head1 DESCRIPTION

The C<Net::SixXS::Diag::None> class implements the L<Net::SixXS::Diag>
role by ignoring all messages passed to its C<debug()> method.

=head1 METHODS

The C<Net::SixXS::Diag::None> class implements the L<Net::SixXS::Diag>
role by supplying a single method named C<debug()> that ignores any messages.

=head1 SEE ALSO

L<Net::SixXS::Diag>, L<Net::SixXS::Diag::MainDebug>

=head1 LICENSE

Copyright (C) 2015  Peter Pentchev E<lt>roam@ringlet.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Peter Pentchev E<lt>roam@ringlet.netE<gt>

=cut

