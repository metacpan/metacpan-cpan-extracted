# -*- perl -*-
#
# Test::AutoBuild::Monitor::Log4perl by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2005 Daniel Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild::Monitor::Log4perl - Monitor progress through a log4perl

=head1 SYNOPSIS

  use Test::AutoBuild::Monitor::Log4perl

  my $monitor = Test::AutoBuild::Log4perl->new()

  # Emit some events
  $monitor->notify("begin-stage", "build", time);
  $monitor->notify("end-stage", "build", time, $status);

=head1 DESCRIPTION

This module sends monitoring events to Log4perl. The events are
logged under the category Test::AutoBuild::Monitor::Log4perl
with a priority of INFO.

=head1 CONFIGURATION

This module merely takes the standard configuration parameters for
C<Test::AutoBuild::Monitor>

=head2 EXAMPLE

  log = {
    label = Log4perl monitor
    module = Test::AutoBuild::Monitor::Log4perl
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Monitor::Log4perl;

use base qw(Test::AutoBuild::Monitor);
use warnings;
use strict;
use Test::AutoBuild::Lib;
use Log::Log4perl;
use Carp qw(confess);

=item $monitor->process($event_name, @args);

This method sends the event name and arguments to Log4Perl
category matching this module's package name. The arguments
are simply sent as a comma separated list.

=cut

sub process {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    my $log = Log::Log4perl->get_logger();

    $log->info($name . ": " . join(", ", @args));
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Monitor>

=cut
