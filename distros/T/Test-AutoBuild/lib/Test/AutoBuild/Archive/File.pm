# -*- perl -*-
#
# Test::AutoBuild::FileArchive by Dennis Gregorovic <dgregorovic@alum.mit.edu>
#
# Copyright (C) 2004 Dennis Gregorovic <dgregorovic@alum.mit.edu>
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

Test::AutoBuild::Archive::File - Archive stored in regular files

=head1 SYNOPSIS

  use Test::AutoBuild::Archive::File;

=head1 DESCRIPTION

This module provides an implementation of L<Test::AutoBuild::Archive>
using a file based storage backend.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Archive::File;

use base qw(Test::AutoBuild::Archive);
use warnings;
use strict;
use Test::AutoBuild::Lib;
use File::Spec::Functions qw(:ALL);
use File::Path;
use File::Find;
use Storable qw(store retrieve dclone);
use Class::MethodMaker
    get_set => [qw(archive_dir)];
use Log::Log4perl;

sub init {
    my $self = shift;
    my %params = @_;

    $self->SUPER::init(@_);

    $self->archive_dir(exists $params{archive_dir} ? $params{archive_dir} : die "archive_dir parameter is required");

    my $dir = catdir($self->archive_dir, $self->key);

    die "no directory found for archive"
	unless -d $dir;
}

sub _get_directory {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;

    if (defined $object) {
	if (defined $bucket) {
	    return File::Spec->catdir($self->archive_dir, $self->key(), $object, $bucket);
	} else {
	    return File::Spec->catdir($self->archive_dir, $self->key(), $object);
	}
    } else {
	return File::Spec->catdir($self->archive_dir, $self->key);
    }
}

sub _save_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;
    my $metadata = shift;

    my $dir = $self->_get_directory($object, $bucket);
    unless (-d $dir) {
	eval {
	    mkpath($dir);
	};
	if ($@) {
	    die "could not create directory '$dir': $@";
	}
    }

    my $data_file = File::Spec->catfile($dir, $type);
    my $log = Log::Log4perl->get_logger();
    $log->debug("Saving metadata of type $type into $dir");
    -e $data_file and die "cannot write to an existing archive: $data_file";

    unless (store $metadata, $data_file) {
	die "cannot write to archive metadata file: $data_file";
    }
}

sub _persist_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $files = shift;
    my $options = shift;

    my $dir = $self->_get_directory($object, $bucket);
    unless (-d $dir) {
	eval {
	    mkpath($dir);
	};
	if ($@) {
	    die "could not create directory '$dir': $@";
	}
    }

    my $file_dir = File::Spec->catdir($dir, "VROOT");
    my $log = Log::Log4perl->get_logger();
    $log->debug("Saving files into $dir");
    -e $file_dir and die "cannot write to an existing archive: $file_dir";
    if (keys %{$files} > 1) {
	eval {
	    mkpath($file_dir);
	};
	if ($@) {
	    die "could not create directory '$file_dir': $@";
	}
    }

    for my $file (keys %{$files}) {
	my $source = catfile($options->{base}, $file);
	my $target = catfile($file_dir, $file);
	$log->debug("Copying $file ($source -> $target)");
	Test::AutoBuild::Lib::copy_files($source,
					 $target,
					 $options);
    }
}

sub _link_files {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;
    my $archive = shift;
    my $options = shift;

    my $file_dir = catdir($archive->_get_directory($module, $bucket), "VROOT");
    my $files = $archive->get_files($module, $bucket);

    my $newoptions = {
	link => ($options->{link} ? 1 : 0),
	move => ($options->{move} ? 1 : 0),
	base => $file_dir,
    };

    $self->_persist_files($module, $bucket, $files, $newoptions);
}

sub _get_objects {
    my $self = shift;

    my $dir = $self->_get_directory();
    opendir(DIR, $dir) or return;
    my @modules = grep { !m/^\.$/ && !m/^\.\.$/ } readdir(DIR);
    closedir DIR;
    return @modules;
}

sub list_buckets {
    my $self = shift;
    my $object = shift;

    my $dir = $self->_get_directory($object);
    opendir(DIR, $dir) or return;
    my @buckets = grep { !m/^\.$/ && !m/^\.\.$/ } readdir(DIR);
    closedir DIR;
    return @buckets;
}


sub _has_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    my $dir = $self->_get_directory($object, $bucket);

    my $data_file = File::Spec->catfile($dir, $type);
    return -e $data_file;
}

sub _get_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    my $dir = $self->_get_directory($object, $bucket);
    my $log = Log::Log4perl->get_logger();
    $log->debug("Trying to get metadata of type $type from $dir");
    my $data_file = File::Spec->catfile($dir, $type);
    -e $data_file or return;

    my $data = retrieve $data_file or return;
    return $data;
}

sub _restore_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $target = shift;
    my $options = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Copying files for $object in $bucket to $target");

    my $dir = $self->_get_directory($object, $bucket);
    my $file_dir = File::Spec->catdir($dir, "VROOT");
    die "no files available to restore" unless -d $file_dir;

    my $files = $self->get_files($object, $bucket);

    for my $file (keys %{$files}) {
	my $src = catfile($file_dir, $file);
	my $dst = catfile($target, $file);
	$log->debug("Copying $file ($src -> $dst)");
	Test::AutoBuild::Lib::copy_files($src,
					 $dst,
					 $options);
    }
}


sub size {
    my $self = shift;
    my $seen_files = shift;

    $seen_files = {} unless defined $seen_files;

    my $total_size = 0;
    my $dir = $self->_get_directory();
    find ({
	no_chdir => 1,
	follow => 0,
	wanted => sub {
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		$atime,$mtime,$ctime,$blksize,$blocks)
		= stat($_);

	    my $key = "$dev.$ino";
	    if (!exists $seen_files->{$key}) {
		$total_size += $size;
		$seen_files->{$key} = 1;
	    }
	}
    }, $dir);
    return $total_size;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Dennis Gregorovic <dgregorovic@alum.mit.edu>
Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2003-2004 Dennis Gregorovic <dgregorovic@alum.mit.edu>,
2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Archive>, L<Test::AutoBuild::ArchiveManager::File>

=cut
