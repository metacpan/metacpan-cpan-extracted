# -*- perl -*-
#
# Test::AutoBuild::Stage::CreateArchive
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2005 Daniel P. Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::CreateArchive - Initialize a new archive instance

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::CreateArchive


=head1 DESCRIPTION

This module creates a new archive instance to be used by later stages
for caching metadata and files for access in subsequent build cycles.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::CreateArchive;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Log::Log4perl;


sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();
    my $arcman = $runtime->archive_manager;
    return unless defined $arcman;

    $log->debug("Creating archive with timestamp " . $runtime->timestamp);
    $arcman->create_archive($runtime->timestamp);
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel P. Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel P. Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Archive>, L<Test::AutoBuild::ArchiveManager>,
L<Test::AutoBuild::Stage::CleanArchive>,  L<Test::AutoBuild::Stage>,
L<Test::AutoBuild::Runtime>

=cut
