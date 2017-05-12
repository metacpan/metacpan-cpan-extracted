# -*- perl -*-
#
# Test::AutoBuild::Result by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Result - represents results of an action

=head1 SYNOPSIS

  use Test::AutoBuild::Result;

=head1 DESCRIPTION

This module provides a representation of the results from an 'interesting'
action of the build process. The results current include a key identifying
the action, status string identifying the outcome of the action, a log of
command output, and start and end times.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Result;

use strict;
use warnings;

use Class::MethodMaker
    new_with_init => "new",
    get_set => [qw(name label status log start_time end_time)];


=item my $resule = Test::AutoBuild::Result->new(%params);

Creates a new result object.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->name(exists $params{name} ? $params{name} : die "name parameter is required");
    $self->label(exists $params{label} ? $params{label} : die "label parameter is required");
    $self->log("");
    $self->status("pending");
    $self->{results} = [];
}

=item my $name = $result->name();

Retrieves the name associated with the result, which is typically an
alpha numeric string.

=item my $label = $result->label();

Retrieves the label associated with the result, which can be free
format text.

=item my $log = $result->log();

Retrieves the log of the output of the action

=item my $status = $result->status();

Retrieves the status of the result, one of 'pending', 'success',
'failed', 'aborted', or 'skipped'.

=item my $time = $result->start_time();

Retrieves the time at which the action began execution, or undefined
if it is yet to run

=item my $time = $result->end_time();

Retrieves the time at which the action completed execution, or undefined
if it is yet to complete

=item $result->add_result($sub_result);

Adds a nested result to this result. The C<$sub_result> parameter should
be another instance of the L<Test::AutoBuild::Result> class.

=item @results = $result->results

Retrieves a list of all nested results, previously added with the
C<add_result> method.

=item $boolean = $result->has_results

Returns a true value if there are nested results

=cut


sub add_result {
    my $self = shift;
    push @{$self->{results}}, shift;
}


sub results {
    my $self = shift;
    return @{$self->{results}};
}


sub has_results {
    my $self = shift;
    return $#{$self->{results}} != -1;
}


sub duration {
    my $self = shift;
    return defined $self->end_time ?
	$self->end_time - $self->start_time :
	undef;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Module>

=cut
