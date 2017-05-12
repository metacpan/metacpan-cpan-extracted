# -*- perl -*-
#
# Test::AutoBuild::Stage::CleanPackages
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

Test::AutoBuild::Stage::CleanPackages - The base class for an AutoBuild stage

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::CleanPackages


=head1 DESCRIPTION

Description

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::CleanPackages;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;

sub process {
    my $self = shift;
    my $runtime = shift;

    my @package_types = $runtime->package_types;

    foreach my $name (@package_types) {
	$runtime->package_type($name)->do_clean;
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
