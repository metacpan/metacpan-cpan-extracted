# -*- perl -*-
#
# Test::AutoBuild::Counter::ChangeList
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2005 Daniel Berrange
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

Test::AutoBuild::Counter::ChangeList - Generates a build counter based on source repository changelist

=head1 SYNOPSIS

  use Test::AutoBuild::Counter::ChangeList;

  my $counter = Test::AutoBuild::Counter::ChangeList->new(options => \%options);

  # Retrieve the current counter
  $counter->value();

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Counter::ChangeList;

use base qw(Test::AutoBuild::Counter);
use warnings;
use strict;
use Log::Log4perl;

=item $counter->generate();

Generates a build counter based on the source repository changelist. If
multiple repositories are configured, the changelists of all of them
will be combined with periods.

=cut

sub generate {
    my $self = shift;
    my $runtime = shift;

    my $repo = $runtime->repository($self->option("repository"));

    return $repo->changelist($runtime);
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
