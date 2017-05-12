# -*- perl -*-
#
# Test::AutoBuild::Archive by Dennis Gregorovic <dgregorovic@alum.mit.edu>
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

Test::AutoBuild::Archive - archival of files and metadata

=head1 SYNOPSIS

  my $manager = [...get instance of Test::AutoBuild::ArchiveManager...]
  my $archive = $manager->get_current_archive;

  my %orig_files = (
    "/usr/src/redhat/RPMS/noarch/autobuild-1.0.0-1.noarch.pm" => ...metadata...
  );

  # Save status of the 'build' action for module 'autobuild-dev'
  $archive->save_data("autobuild-dev",
		      "build",
		      "success");

  # Save list of packages associated with module 'autobuild-dev'
  $archive->save_files("autobuild-dev",
		       "packages",
		       \%orig_files,
		       { link => 1,
			 move => 1,
			 base => "/usr/src/redhat"});


  # Retrieve status of the 'build' action for module 'autobuild-dev'
  my $status = $archive->get_data("autobuild-dev",
				  "build");

  # Retrieve metadata associated with saved files
  my $metadat = $archive->get_files("autobuild-dev",
				    "packages");

  # Save RPMSs to an HTTP site
  $archive->extract_files("autobuild-dev",
			  "packages",
			  "/var/www/html/packages/autobuild-dev",
			  { link => 1 });


=head1 DESCRIPTION

The C<Test::AutoBuild::Archive> module provides an API for
associating chunks of data and files, with objects, persisting
them to some form of storage. Each object in the archive is
uniquely identified by an alphanumeric string, and can in turn
contain many storage buckets, again uniquely identified by an
alphanumeric string. An individual bucket can store a chunk of
metadata, and a set of files at any one time. Each file stored
can also have a chunk of associated metadata. Conceptually the
organization of an archive is thus

 ROOT
  |
  +- myobject
  |   |
  |   +- mybucket
  |   |   |
  |   |   +- DATA       - chunk of generic metadata
  |   |   +- FILES      - set of files
  |   |   +- FILE-DATA  - chunk of metadata about FILES
  |   |
  |   +- otherbucket
  |   |   |
  |   |   +- DATA       - chunk of generic metadata
  |   |   +- FILES      - set of files
  |   |   +- FILE-DATA  - chunk of metadata about FILES
  |   |
  |   +- ...
  |
  +- otherobject
  |   |
  |   +- mybucket
  |   |   |
  |   |   +- DATA       - chunk of generic metadata
  |   |   +- FILES      - set of files
  |   |   +- FILE-DATA  - chunk of metadata about FILES
  |   |
  |   +- otherbucket
  |   |   |
  |   |   +- DATA       - chunk of generic metadata
  |   |   +- FILES      - set of files
  |   |   +- FILE-DATA  - chunk of metadata about FILES
  |   |
  |   +- ...
  |
  +- ...


=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Archive;

use warnings;
use strict;
use File::Spec::Functions qw(:ALL);
use Storable qw(dclone);
use Class::MethodMaker
    new_with_init => qw(new),
    get_set => [qw(key created)];
use Log::Log4perl;

sub init {
    my $self = shift;
    my %params = @_;

    die ref($self) . " is an abstract module and must be sub-classed"
	if ref($self) eq "Test::AutoBuild::Archive";

    $self->key(exists $params{key} ? $params{key} : die "key parameter is required");
    $self->created(exists $params{created} ? $params{created} : time);
}

=item $archive->save_data($object, $bucket, $data);

Save a chunk of data C<$data> associated with object C<$object>
into the storage bucket named C<$bucket>. Both the C<$object>
and C<$bucket> parameters must be plain strings comprising
characters from the set 'a'..'z','A'..'Z','0'-'9','-','_'
and '.'. The C<$data> can be comprised scalars, array references
and hash references. Code references and file handles are forbidden.
If there is already data present in the bucket C<$bucket> associated
with the object C<$object> then an error will be thrown. The data
can later be retrieved from the archive by calling the C<get_data>
method with matching arguments for object and bucket.

=cut

sub save_data {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $data = shift;

    $self->_save_metadata($object, $bucket, "DATA", $data);
}

=item $archive->save_files($object, $bucket, $files, $options)

Saves a set of files C<$files> associated with object C<$object>
into the storage bucket named C<$bucket>. Both the C<$object>
and C<$bucket> parameters must be plain strings comprising
characters from the set 'a'..'z','A'..'Z','0'-'9','-','_'
and '.'. The C<$files> parameter should be a hash reference where
the keys are fully qualified file names, and the values are arbitrary
chunks of data, comprised of scalars, array references and hash
references. Code references and file handles are forbidden. If
there are already files present in the bucket C<$bucket> associated
with the object C<$object> then an error will be thrown. The data
can later be retrieved from the archive by calling the C<extract_files>
method with matching arguments for object and bucket. A listing of
files stored in the archive can be retrieved by calling the method
C<get_files> with matching arguments for object and  bucket.
The C<$options> parameter controls the way in which the files
are stored. It can contain the following keys

=over 4

=item link

Attempt to hardlink the files into the archive, rather than
doing a regular copy. In combination with same option on the
C<extra_files> and C<attach_files> methods, this allows for
considerable conversation of disk space, by only ever having
one copy of the data no matter how many locations the file
is kept. Care must be taken, however, to ensure that the contents
of the original file is not modified after the archive is saved.
If omitted, defaults to 0.

=item move

Delete the original file after copying it into the archive.
This can also be used in combination with the C<link> option
as protect. If omitted, defaults to 0

=item base

When storing the filenames, trim the directory prefix specified
by the value to this option, off the front of the filenames to
form a relative filename. This can be useful when later extracting
the files back out to an alternate directory. If omitted, defaults
to the root directory.

=item flatten

When storing the filenames, trim off the entire directory prefix,
only maintaining the basic filename. If two files have the same
filename after trimming, an error will be thrown. If omitted, defaults
to 0.

=back

This method returns a hash reference, whose keys are the filenames
saved, relative to the value associated with the C<base> key in
the C<$options> parameter.

=cut

sub save_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $files = shift;
    my $options = shift;

    $options = {} unless defined $options;

    my $newoptions = {
	link => ($options->{link} ? 1 : 0),
	move => ($options->{move} ? 1 : 0),
	base => ($options->{base} ? $options->{base} : rootdir()),
    };

    my $copied = {};
    my $empty = 1;
    for my $file (keys %{$files}) {
	my $fragment = abs2rel($file, $newoptions->{base});
	$copied->{$fragment} = dclone($files->{$file});
	$empty = 0;
    }
    return {} if $empty;

    $self->_persist_files($object, $bucket, $copied, $newoptions);
    $self->_save_metadata($object, $bucket, "FILES", $copied);

    return $copied;
}


=item $archive->_save_metadata($object, $bucket, $datatype, $data);

This an internal method to be implemented by subclasses, to
provide the actual storage for metadata. The C<$object> and
C<$bucket> parameters are as per the C<save_data> or C<save_files>
methods. The C<datatype> parameter is a key, either C<DATA>
to indicate general metadata being saved, or C<FILES> to indicate
the per file metadata. Finally, the C<$data> parameter is the
actual data to be saved, which may be a scalar, hash reference or
array reference, nested to arbitrary depth. Implementations must
throw an error if the archive already contains data stored against
the tuple (C<$object>,C<$bucket>,C<$type>).

=cut

sub _save_metadata {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $type = shift;
    my $data = shift;

    die "module " . ref($self) . " forgot to implement the save_metadata method";
}


=item my $copied = $archive->clone_files($object, $bucket, $archive, $options);

This method copies the files associated with the object
C<$object> in bucket C<$bucket> in the archive C<$archive>
over to this archive. If the C<link> key is specified as
an option, then implementations are free to implement this
as a zero-copy operation to save storage. This method returns
a hash reference whose keys are the list of filenames, relative
to their original base directory, and whose values are the
metadata associated with each file.

=cut

sub clone_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $archive = shift;
    my $options = shift;

    my $newoptions = {
	link => ($options->{link} ? 1 : 0),
	move => ($options->{move} ? 1 : 0),
    };

    return {} unless $archive->has_files($object, $bucket);

    my $copied = $archive->get_files($object, $bucket);

    $self->_link_files($object, $bucket, $archive, $newoptions);
    $self->_save_metadata($object, $bucket, "FILES", $copied);

    return $copied;
}

=pod

=item $archive->_persist_files($object, $bucket, $files, $options);

This an internal method to be implemented by subclasses, to
provide the actual storage for metadata. The C<$object> and
C<$bucket> parameters are as per the C<save_data> or C<save_files>
methods. The C<$files> parameter is a hash reference detailing the
files to be persisted. The keys of the hash reference are filenames
relative to the directory specified by the C<base> key in the
C<$options> parameter. The C<$options> parameter can also contain
the keys C<link> to indicate zero-copy persistence of files, and
C<move> to indicate the original file should be deleted.

=cut

sub _persist_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;

    die "module " . ref($self) . " forgot to implement the persist_files method";
}

sub _link_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;

    die "module " . ref($self) . " forgot to implement the link_files method";
}


=item my @objects = $archive->list_objects

Retrieves a list of all objects which have either files or
metadata stored in this archive. The returned list of objects
is sorted alphabetically.

=cut

sub list_objects {
    my $self = shift;

    return sort { $a cmp $b } $self->_get_objects();
}

=item my @objects = $archive->_get_objects

This is an internal method used to retrieve the list of
objects stored in the archive. This should return a list
of objects stored, but need not sort them in any particular
order. This method must be implemented by subclasses.

=cut

sub _get_objects {
    my $self = shift;

    die "module " . ref($self) . " forgot to implement the _get_objects method";
}

=item my @buckets = $archive->list_buckets($object)

Retrieves a list of all storage buckets associated
with the object C<$object>. The returned list of buckets
is not sorted in any particular order. If the object
C<$object> is not stored in this archive, then the empty
list is to be returned. This method must be implemented
by subclasses.

=cut

sub list_buckets {
    my $self = shift;
    my $object = shift;

    return $self->_get_buckets($object);
}

sub _get_buckets {
    my $self = shift;
    my $object = shift;

    die "module " . ref($self) . " forgot to implement the get_buckets method";
}


=item my $data = $archive->get_data($object, $bucket);

Retrieves the data in the bucket C<$bucket> associated
with the object C<$object>, which was previously stored
with the C<save_data> method.

=cut

sub get_data {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;

    return {} unless $self->has_data($module, $bucket);

    return $self->_get_metadata($module, $bucket, "DATA");
}


sub get_files {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;

    return {} unless $self->has_files($module, $bucket);

    return $self->_get_metadata($module, $bucket, "FILES");
}

sub _get_metadata {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;

    die "module " . ref($self) . " forgot to implement the _get_metadata method";
}

sub _has_metadata {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;
    my $type = shift;

    die "module " . ref($self) . " forgot to implement the _has_metadata method";
}

sub has_files {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;

    return $self->_has_metadata($module, $bucket, "FILES");
}

sub has_data {
    my $self = shift;
    my $module = shift;
    my $bucket = shift;

    return $self->_has_metadata($module, $bucket, "DATA");
}

sub extract_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $target = shift;
    my $options = shift;

    $options = {} unless defined $options;

    return {} unless $self->has_files($object, $bucket);

    my $newoptions = {
	link => ($options->{link} ? 1 : 0),
	move => ($options->{move} ? 1 : 0),
    };

    my $copied = $self->get_files($object, $bucket);
    my $restored = {};
    my $empty = 1;
    foreach my $file (keys %{$copied}) {
	my $dst = catfile($target, $file);
	$restored->{$dst} = dclone($copied->{$file});
	$empty = 0;
    }
    return {} if $empty;

    $self->_restore_files($object,$bucket,$target,$newoptions);

    return $restored;
}

sub _restore_files {
    my $self = shift;
    my $object = shift;
    my $bucket = shift;
    my $target = shift;
    my $options = shift;

    die "module " . ref($self) . " forgot to implement the _restore_files method";
}


sub size {
    my $self = shift;
    my $seen = shift;

    die "module " . ref($self) . " forgot to implement the size method";
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Dennis Gregorovic <dgregorovic@alum.mit.edu>, Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2003-2004 Dennis Gregorovic <dgregorovic@alum.mit.edu>,
Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::ArchiveManager>, L<Test::AutoBuild::Archive::File>

=cut
