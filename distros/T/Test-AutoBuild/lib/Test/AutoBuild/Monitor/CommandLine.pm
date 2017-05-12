# -*- perl -*-
#
# Test::AutoBuild::Monitor::CommandLine by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Monitor::CommandLine - Monitor progress from 'ps'

=head1 SYNOPSIS

  use Test::AutoBuild::Monitor::CommandLine

  my $monitor = Test::AutoBuild::CommandLine->new()

  # Emit some events
  $monitor->notify("beginStage", "build", time);
  $monitor->notify("endStage", "build", time, $status);

=head1 DESCRIPTION

This module changes the process command line to reflect the current
status. Thus the status can be viewed simply by running the 'ps'
command. For example, after a single beginStage event for stage
name 'build' it will show

   auto-build [running build]

After a second beginStage for stage name 'isos'

   auto-build [running build->isos]

After the second finishes

   auto-build [running build]

If there is a nested beginBuild event for module 'foo':

   auto-build [running build (foo)]

etc, etc.

=head1 CONFIGURATION

This module merely uses the standard configuration parameters for
C<Test::AutoBuild::Monitor>, no options are neccessary

=head2 EXAMPLE

  cmd = {
    label = Command line monitor
    module = Test::AutoBuild::Monitor::CommandLine
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Monitor::CommandLine;

use base qw(Test::AutoBuild::Monitor);
use warnings;
use strict;
use Test::AutoBuild::Lib;
use Carp qw(confess);
use POSIX qw(mkfifo);

=item $monitor->init(%params);

This method initializes a new monitor & is called automatically
by the C<new> method. The C<%params> parameters are passed through
from the C<new> method.

=cut

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->{command} = $0;
    $self->{stages} = [];
    $self->{module} = undef;
}

=item $monitor->process($event_name, @args);

This method changes the contents of $0 to reflect current
build state. It understands the following events (which can
be nested): C<beginStage>, C<completeStage>, C<failStage>,
C<abortStage>, C<beginBuild>, C<endBuild>. C<beginCheckout>,
C<endCheckout>. All other events are ignored.

=cut

sub process {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    if ($name eq "beginStage") {
	push @{$self->{stages}}, $args[0];

	$self->{module} = undef;
    } elsif ($name eq "completeStage" ||
	     $name eq "failStage" ||
	     $name eq "abortStage") {
	pop @{$self->{stages}};
	$self->{module} = undef;
    } elsif ($name eq "beginBuild") {
	$self->{module} = $args[0];
    } elsif ($name eq "endBuild") {
	$self->{module} = undef;
    } elsif ($name eq "beginCheckout") {
	$self->{module} = $args[0];
    } elsif ($name eq "endCheckout") {
	$self->{module} = undef;
    }

    $0 = $self->{command} .
	" [running " . join("->", @{$self->{stages}}) .
	($self->{module} ? " (" . $self->{module} . ")]" : "]");
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
