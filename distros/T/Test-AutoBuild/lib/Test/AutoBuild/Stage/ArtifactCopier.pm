# -*- perl -*-
#
# Test::AutoBuild::Stage::ArtifactCopier by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::ArtifactCopier - Copies build artifacts to a directory

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::ArtifactCopier


=head1 DESCRIPTION

This module copies the artifacts of each module to an HTTP or FTP
site.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::ArtifactCopier;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;

use Test::AutoBuild::Lib;
use File::Path;
use File::Spec::Functions;


sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();

    my $module = shift;
    my @modules = defined $module ? ( $module ) : $runtime->modules();

    my $directory = $self->option("directory");
    die "directory parameter is required" unless $directory;

    # By default, remove the old contents of the directory.  This can be overridden by setting
    # the 'clean-directory' parameter to 0
    my $clean = $self->option("clean-directory");
    $clean = 1 unless ( defined ($clean) && $clean == 0 );
    if ( $clean ) {
	$log->debug("Cleaning artifact directories");
	if ( $directory =~ m,\%m, ) {
	    foreach my $name (@modules) {
		$log->info("Removing contents of $directory");
		$directory = $self->option("directory");
		$directory =~ s,\%m,$name,g;
		Test::AutoBuild::Lib::delete_files($directory);
	    }
	} else {
	    Test::AutoBuild::Lib::delete_files($directory);
	}
    }

    foreach my $name (@modules) {
	$log->debug("Copying artifacts for $name");
	my $dst_base = $self->option("directory");
	$dst_base =~ s,\%m,$name,g;

	my $src_base = $runtime->module($name)->dir;

	eval {
	    mkpath($dst_base);
	};
	if ($@) {
	    die "could not create directory '$dst_base': $@";
	}

	foreach my $artifact (@{$runtime->module($name)->artifacts}) {
	    my $src = catfile($src_base, $artifact->{src});
	    my $dst = catfile($dst_base, $artifact->{dst});

	    my $publisher = $runtime->publisher($artifact->{publisher});

	    $log->info("Copying $src to $dst with publisher '" . $publisher->name . "'");

	    die "cannot find publisher $artifact->{publisher}\n"
		unless $publisher;

	    # Only try copying if its a single file which exists,
	    # or if its a globbed path
	    if (-e $src or $src =~ /\*/) {
		$publisher->publish($src, $dst);
	    } else {
		$log->warn("Skipping $src because it does not exist");
	    }
	}
    }
}



1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>

=cut
