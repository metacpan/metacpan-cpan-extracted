# -*- perl -*-
#
# Test::AutoBuild::Change by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Change - Details of change in source control repository

=head1 SYNOPSIS

  use Test::AutoBuild::Change

=head1 DESCRIPTION

This module provides a representation of a change in a source control
repository. The C<export> method on the L<Test::AutoBuild::Repository>
class will returns a hash reference containing this objects as values
to represent the list of changes since the previous call to C<export>

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Change;

use strict;
use warnings;

use Class::MethodMaker
    new_with_init => "new",
    get_set => [qw(number date user description files)];


=item my $change = Test::AutoBuild::Change->new(%params);

Creates a new change object, initializing with a set of
named parameters. The C<number> parameter is a number
representing the change, typically either a plain integer,
or a version string (ie set of period separated integers).
The C<date> parameter specifies in seconds since the epoch,
date the change was made. The C<user> parameter is a
representation of the user who made the change, typically
their username. The C<description> parameter provides the
log message for the change. Finally the C<files> parameter
is an array reference listing all the files affected by
the changelist.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->number(exists $params{number} ? $params{number} : die "number parameter is required");
    $self->date(exists $params{date} ? $params{date} : die "date parameter is required");
    $self->user(exists $params{user} ? $params{user} : die "user parameter is required");
    $self->description(exists $params{description} ? $params{description} : die "description parameter is required");
    $self->files(exists $params{files} ? $params{files} : die "files parameter is required");
}

=item my $number = $change->number();

Retrieves the number associated with this change. This is
typically an integer (eg 43212), or a version string (eg
1.5.2).

=item my $date = $change->date();

Retrieves the date on which the change was made. This is
in seconds since the epoch.

=item my $user = $change->user();

Retrieves the user who made the change, typically the username
under which the repository was accessed.

=item my $log = $change->description();

Retrieves the log message associated with this change.

=item my $fils = $change->files();

Retrieves an array reference specifying the list of files affected
by this change.

=cut

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Repository>

=cut
