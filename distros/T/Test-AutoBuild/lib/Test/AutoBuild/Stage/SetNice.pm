# -*- perl -*-
#
# Test::AutoBuild::Stage::SetNice
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004 Red Hat, Inc.
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

Test::AutoBuild::Stage::SetNice - Alter the scheduling priority of builder

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::SetNice


=head1 DESCRIPTION

This module provides the ability to alter the scheduling priority of
the build process, typically lowering it to avoid monopolising all
the resources of the host machine. This is analogous to launching
the builder process through the L<nice(1)> command.

=head1 CONFIGURATION

In addition to the standard parameters defined by the L<Test::AutoBuild::Stage>
module, this module accepts one entry in the C<options> parameter:

=over 4

=item nice-level

An integer in the range -20 (highest priority) to 19 (lowest priority)
indicating what schedular priority to give to the builder. NB, typically
you will be unable to set a priority less than zero, since the builder
does not run as root. If omitted, the default value is 19 to ensure lowest
priority is taken.

=back

=head2 EXAMPLE

  {
    name = renice
    label = Set Process Priority
    module = Test::AutoBuild::Stage::SetNice
    critical = 0
    options = {
      nice-level = 19
    }
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::SetNice;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use BSD::Resource;
use Log::Log4perl;


=item $stage->init(%params);

Override super class to initialize the default nice level if non
was specified. It is not neccesary to call this method since it
is called automatically by the C<new> method.

=cut

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    $self->option("nice-level", 19) unless defined $self->option("nice-level");
}

=item $stage->process($runtime);

Attempt to change the priority of the builder process according
to the C<nice-level> option. If unsuccessful, marks the stage as
having C<failed>. Since this is a recoverable error, it is usual
to set this stage as non-critical.

=cut

sub process {
    my $self = shift;
    my $runtime = shift;

    #----------------------------------------------------------------------
    # Renice ourselves so we don't monopolise the machine
    my $nice_level = $self->option('nice-level');
    my $log = Log::Log4perl->get_logger();
    $log->debug("Renicing to level $nice_level");
    unless(setpriority PRIO_PROCESS, $$, $nice_level) {
	$self->fail("cannot renice to $nice_level: $!");
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc.

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>

=cut
