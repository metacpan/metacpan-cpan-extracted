# -*- perl -*-
#
# Test::AutoBuild::Stage::Copier by Daniel P. Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::Copier - Abstract base module for copying files

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Copier


=head1 DESCRIPTION

This module provides an abstract base module to use for copying files,
such as generated packages, log files, or artifacts.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Copier;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use File::Path;
use Log::Log4perl;
use Test::AutoBuild::Lib;

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    my $directories = $self->option("directories");
    if (!defined $directories) {
	if (defined $self->option("directory")) {
	    $directories = [$self->option("directory")];
	} else {
	    die "directories parameter is required" unless $directories;
	}
    }

    # By default, remove the old contents of the directory.  This
    # can be overridden by setting the 'clean-directory' parameter to 0
    my $clean = $self->option("clean-directory");
    $clean = 1 unless ( defined ($clean) && $clean == 0 );

    for my $directory (@$directories) {
	my $exp_directories = Test::AutoBuild::Lib::_expand_standard_macros([[ $directory, $directory, {} ]], $runtime);
	if ($clean) {
	    for my $exp_directory (@$exp_directories) {
		Test::AutoBuild::Lib::delete_files($exp_directory->[1]);
	    }
	}
	for my $exp_directory (@$exp_directories) {
	    my $directory_name = $exp_directory->[1];
	    my $directory_attrs = $exp_directory->[2];
	    $self->handle_directory($runtime, $directory_name, $directory_attrs);
	}
    }
}

sub handle_directory {
    my $self = shift;

    die "class " . ref($self) . " forgot to implement the handle_directory method";
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

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Stage::LogCopier>, L<Test::AutoBuild::Stage::PackageCopier>

=cut
