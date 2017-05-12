# -*- perl -*-
#
# Test::AutoBuild::Stage::PackageCopier by Daniel P. Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2005 Daniel P. Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::PackageCopier - Copy generated packages to a distribution site

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::PackageCopier


=head1 DESCRIPTION

This module provides a means to copy generated packages to a distribution
site (eg web site, or FTP server).

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::PackageCopier;

use base qw(Test::AutoBuild::Stage::Copier);
use warnings;
use strict;
use File::Path;
use Log::Log4perl;


sub handle_directory {
    my $self = shift;
    my $runtime = shift;
    my $directory_name = shift;
    my $directory_attrs = shift;

    my @modules = $runtime->modules();

    my $log = Log::Log4perl->get_logger();

    for my $name (@modules) {
	if (!exists $directory_attrs->{'module'} || $directory_attrs->{'module'} eq $name) {
	    my $packages = $runtime->module($name)->packages();
	    foreach my $filename (keys %{$packages}) {
		if (!exists $directory_attrs->{'package_type'} ||
		    $directory_attrs->{'package_type'} eq $packages->{$filename}->type()->name()) {
		    mkpath($directory_name);
		    $log->info("Copy $filename $directory_name");
		    Test::AutoBuild::Lib::copy_files($filename, $directory_name, { 'link' => 1 });
		}
	    }
	}
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Dennis Gregorovic <dgregorovic@alum.mit.edu>
Daniel P. Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel P. Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Stage::Copier>

=cut
