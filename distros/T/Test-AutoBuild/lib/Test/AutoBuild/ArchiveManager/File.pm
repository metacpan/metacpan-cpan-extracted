# -*- perl -*-
#
# Test::AutoBuild::ArchiveManager::File
#
# Daniel Berrange <dan@berrange.com>
# Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004-2005 Dennis Gregorovice, Daniel Berrange
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

Test::AutoBuild::ArchiveManager::File - Disk based archive manager

=head1 SYNOPSIS

  use Test::AutoBuild::ArchiveManager::File;


=head1 METHODS

=over 4

=cut

package Test::AutoBuild::ArchiveManager::File;

use base qw(Test::AutoBuild::ArchiveManager);
use warnings;
use strict;
use File::Spec::Functions;
use File::Path;
use Test::AutoBuild::Archive::File;
use Log::Log4perl;
use Class::MethodMaker
    get_set => [qw(archive_dir)];

sub init {
    my $self = shift;
    my %params = @_;

    $self->SUPER::init(@_);

    $self->archive_dir(defined $self->option("archive-dir") ? $self->option("archive-dir") : die "archive-dir option is required");
}


sub create_archive {
    my $self = shift;
    my $key = shift;

    my $dir = catdir($self->archive_dir, $key);
    die "archive with key $key already exists"
	if -d $dir;

    eval {
	mkpath($dir);
    };
    if ($@) {
	die "could not create directory '$dir': $@";
    }
}

sub _get_directory {
    my $self = shift;

    return $self->option("archive-dir");
}

sub delete_archive {
    my $self = shift;
    my $key = shift;

    my $dir = catdir($self->archive_dir, $key);

    die "archive with key $key does not exist"
	unless -d $dir;

    rmtree $dir;
}

sub list_archives {
    my $self = shift;

    my $dir = $self->_get_directory;
    opendir(DIR, $dir) or return;
    my @archives = sort { $a <=> $b } grep { !m/^\.$/ && !m/^\.\.$/ } readdir(DIR);
    closedir DIR;

    return map {
	Test::AutoBuild::Archive::File->new(key => $_,
					    archive_dir => $self->archive_dir);
    } @archives;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,
Dennis Gregorovic <dgregorovic@alum.mit.edu>

=head1 COPYRIGHT

Copyright (C) 2004-2005 Dennis Gregorovic, Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>

=cut
