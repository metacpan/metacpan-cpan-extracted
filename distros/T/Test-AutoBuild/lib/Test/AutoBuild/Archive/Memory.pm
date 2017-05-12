# -*- perl -*-
#
# Test::AutoBuild::Archive::Memory by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Archive::Memory - Archive stored (transiently) in memory

=head1 SYNOPSIS

  use Test::AutoBuild::Archive::Memory;

=head1 DESCRIPTION

This module provides an implementation of L<Test::AutoBuild::Archive>
using an in-memory hash table as the storage backend.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Archive::Memory;

use base qw(Test::AutoBuild::Archive);
use warnings;
use strict;
use Log::Log4perl;

sub init {
    my $self = shift;
    my %params = @_;

    $self->SUPER::init(@_);
    $self->{objects} = {};
}

sub _save_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;
    my $metadata = shift;

    $self->{objects}->{$object} = {} unless exists $self->{objects}->{$object};
    $self->{objects}->{$object}->{$bucket} = {} unless exists $self->{objects}->{$object}->{$bucket};
    $self->{objects}->{$object}->{$bucket}->{$type} = $metadata;
}

sub _has_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    return 0 unless exists $self->{objects}->{$object};
    return 0 unless exists $self->{objects}->{$object}->{$bucket};
    return 0 unless exists $self->{objects}->{$object}->{$bucket}->{$type};
    return 1;
}

sub _persist_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $files = shift;
    my $options = shift;

    my $store = [];
    $self->{objects}->{$object} = {} unless exists $self->{objects}->{$object};
    $self->{objects}->{$object}->{$bucket} = {} unless exists $self->{objects}->{$object}->{$bucket};
    $self->{objects}->{$object}->{$bucket}->{FILES} = $store;

    for my $file (keys %{$files}) {
	$self->_persist_file($store, $file, $options);
    }
}

sub _persist_file {
    my $self = shift;
    my $store = shift;
    my $file = shift;
    my $options = shift;

    my $src = catfile($options->{base}, $file);

    my $record = { type => "unknown", file => $file, mode => $file->mode };
    push @{$store}, $record;
    if (-d $file) {
	$record->{type} = "dir";
	opendir DIR, $src
	    or die "cannot open $src: $!";
	my @subfiles = readdir DIR;
	closedir DIR;
	foreach my $subfile (@subfiles) {
	    next if $subfile =~ /^(\.)|(\.\.)$/;
	    $self->_persist_file($store, catfile($file,$subfile), $options);
	}
    } elsif (-l $src) {
	my $dst = readlink $src;
	$record->{dest} = $dst;
	$record->{type} = "link";
    } elsif (-f $src) {
	local $/ = undef;
	open FILE, "<$src"
	    or die "cannot read $src: $!";
	my $data = <FILE>;
	close FILE;
	$record->{type} = "file";
	$record->{data} = $data;
    } else {
	warn "Unhandled file $src which isn't link/dir/plain";
    }
}

sub _get_objects {
    my $self = shift;

    return keys %{$self->{objects}};
}

sub _get_buckets {
    my $self = shift;
    my $object = shift;

    return () unless exists $self->{objects}->{$object};

    return keys %{$self->{objects}->{$object}};
}

sub _get_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;

    return undef unless exists $self->{objects}->{$object};
    return undef unless exists $self->{objects}->{$object}->{$bucket};

    return $self->{objects}->{$object}->{$bucket}->{$type};
}

sub _restore_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $target = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Copying files for $object in $bucket to $target");

    return unless exists $self->{objects}->{$object};
    return unless exists $self->{objects}->{$object}->{$bucket};

    my $store = $self->{objects}->{$object}->{$bucket}->{FILES};

    foreach my $file (@{$store}) {
	$self->_restore_file($file, $target);
    }
}

sub _restore_file {
    my $self = shift;
    my $file = shift;
    my $target = shift;

    my $name = catfile($target, $file->{file});
    if ($file->{type} eq "file") {
	open FILE, ">$name"
	    or die "cannot create $name: $!";
	print FILE $file->{data};
	close FILE;
	chmod $name, $file->{mode};
    } elsif ($file->{type} eq "dir") {
	mkdir $name, 0755;
	chmod $name, $file->{mode};
    } elsif ($file->{type} eq "link") {
	symlink $name, $file->{dest};
    } else {
	warn "Unhandled type for " . $file->{file};
    }
}


sub size {
    my $self = shift;

    my $size = 0;
    foreach my $object (%{$self->{objects}}) {
	foreach my $bucket (%{$self->{objects}->{$object}}) {
	    my $files = $self->{objects}->{$object}->{$bucket}->{FILES};
	    if ($files) {
		foreach my $file (@{$files}) {
		    if ($file->{type} eq "file") {
			$size += length $file->{data};
		    }
		}
	    }
	}
    }
    return $size;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Archive>, L<Test::AutoBuild::ArchiveManager::Memory>

=cut
