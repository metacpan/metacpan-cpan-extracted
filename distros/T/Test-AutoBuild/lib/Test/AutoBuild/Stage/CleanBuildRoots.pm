# -*- perl -*-
#
# Test::AutoBuild::Stage::CleanBuildRoots
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

Test::AutoBuild::Stage::CleanBuildRoots - Clean up files in build install root

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::CleanBuildRoots

  my $stage = Test::AutoBuild::Stage::CleanBuildRoots->new(name => "cleanroot", label => "Clean Roots")
  $stage->run($runtime);

=head1 DESCRIPTION

This module is responsible for cleaning up the build installation root.
It basically just recursively removes all files and directories in the
location specified by the C<install_root> method on the L<Test::AutoBuild::Runtime>
object.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::CleanBuildRoots;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use File::Spec::Functions;
use File::Path;
use Log::Log4perl;
use Test::AutoBuild::Lib;

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    # delete all install roots
    my $install_root = $runtime->install_root;

    if (-d $install_root) {
	$log->debug("Removing files in install root '$install_root'");
	Test::AutoBuild::Lib::delete_files($install_root);
    }

    if (!-d $install_root) {
	$log->debug("Creating install_root '$install_root'");
	mkpath($install_root, 0, 0775);
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004 Red Hat, Inc, 2004-2005 Daniel Berrange

=head1 SEE ALSO

L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Runtime>

=cut
