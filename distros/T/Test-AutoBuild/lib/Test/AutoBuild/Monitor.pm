# -*- perl -*-
#
# Test::AutoBuild::Monitor by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Monitor - Builder progress monitor

=head1 SYNOPSIS

  use Test::AutoBuild::Monitor

  my $rep = Test::AutoBuild::Monitor->new(
	       name => "foo",
	       label => "Some thing",
	       enabled => 1,
	       options => \%options,
	       env => \%env);

  # Add a module to the repository
  $rep->module($module_name, $module);

  # Initialize the repository
  $rep->init();

  # Checkout / update the module
  my $changed = $rep->export($name, $module);

=head1 DESCRIPTION

This module provides the API for interacting with the source
control repositories. A repository implementation has to be
able to do two main things

 * Get a checkout of a new module
 * Update an existing checkout, determining if any
   changes where made

=head1 CONFIGURATION

The valid configuration options for the C<repositories> block are

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Monitor;

use warnings;
use strict;
use Class::MethodMaker
    new_with_init => 'new',
    get_set => [qw( name label is_enabled )];

=item my $monitor = Test::AutoBuild::Monitor->new(name => $name,
						  label => $label,
						  [enabled => $enabled,]
						  [options => \%options,]
						  [env => \%env]);

This method creates a new monitor. The C<name> parameter specifies a
short alpha-numeric name for the monitor. The C<label> parameter specifies
an arbitrary label for presenting to usres. The optional C<options> argument
is a hashref of implementation specific options. The optional C<env>
argument is a hashref of environment variables to set when handling
notifications.

=item $monitor->init(%params);

This method initializes the monitor object & is called automatically
from the C<new> method with the named parameters passed to that method.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->name(exists $params{name} ? $params{name} : die "name parameter is required");
    $self->label(exists $params{label} ? $params{label} : die "label parameter is required");
    $self->is_enabled(exists $params{enabled} ? $params{enabled} : 1);

    $self->{options} = exists $params{options} ? $params{options} : {};
    $self->{env} = exists $params{env} ? $params{env} : {};
}


=item my $name = $monitor->name([$newname]);

Retrieves the name of this monitor, a short alpha-numeric token.
If the optional C<$newname> parameter is specified then the name
is updated.

=item my $name = $monitor->label([$newname]);

Retrieves the name of this monitor, a short alpha-numeric token.
If the optional C<$newname> parameter is specified then the name
is updated.

=item my $name = $monitor->is_enabled([$state]);

Returns a true value if this monitor is marked as enabled.
If the optional C<$status> parameter is specified then the enabled
state is updated. If this method returns a false value, then the
C<notify> method will not call C<process>, effectively becoming a
no-op

=item my $monitor->notify($event_name, @args);

Send a notification to this monitor. The C<$event_name> parameter
is a short alpha-numeric token representing the event triggering
this notification. The C<@args> params are arbitrary data items
specific to this event. If the C<is_enabled> method returns a true
value, this method will invoke the C<proces> method to actually
handle the event, otherwise it will be a no-op

=cut

sub notify {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    if ($self->is_enabled()) {
	local %ENV = %ENV;
	foreach (keys %{$self->{env}}) {
	    $ENV{$_} = $self->{env}->{$_};
	}
	$self->process($name, @args);
    }
}

=item my $monitor->process($event_name, @args);

This method must be implemented by sub-classes to provide the
notification processing they require. The default implementation
will simply call die. The arguments are the same as those for
the C<notify> method.

=cut

sub process {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    die "class " . ref($self) . " forgot to implement the notify method";
}

=item my $value = $rep->option($name[, $value]);

When run with a single argument, retuns the option value corresponding to
the name specified in the first argument. If a second argument is supplied,
then the option value is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}

=item my $value = $rep->env($name[, $value]);

When run with a single argument, retuns the environment variable corresponding
to the name specified in the first argument. If a second argument is supplied,
then the environment variable is updated.

=cut

sub env {
   my $self = shift;
   my $name = shift;

   $self->{env}->{$name} = shift if @_;
   return $self->{env}->{$name};
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Monitor::CommandLine>, L<Test::AutoBuild::Monitor::Log4perl>, L<Test::AutoBuild::Monitor::Pipe>

=cut
