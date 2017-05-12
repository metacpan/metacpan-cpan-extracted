package MogileFS::Client::FilePaths;

=head1 NAME

MogileFS::Client::FilePaths - Client library for use with FilePaths plugin in MogileFS

=head1 SYNOPSIS

 use MogileFS::Client::FilePaths;

 # From MogileFS::Client (See its documentation for details)
 $mogc = MogileFS::Client->new(domain => "foo.com::my_namespace",
                               hosts  => ['10.0.0.2', '10.0.0.3']);

 $key   = "/path/to/file";   # The FilePaths plugin lays a path structure on top of standard mogilefs.
 $class = "user_images";     # Files still belong to classes
 $fh = $mogc->new_file($key, $class);

 print $fh $data;

 unless ($fh->close) {
    die "Error writing file: " . $mogc->errcode . ": " . $mogc->errstr;
 }

 # Find the URLs that the file was replicated to.  May change over time.
 @urls = $mogc->get_paths($key);

 # no longer want it?
 $mogc->delete($key);

 # List files in a directory
 @files = $mogc->list("/path/to");

 # Each element is a hashref, see below for more keys.
 @file_names = map { $_->{name} } @files;

=head1 DESCRIPTION

This module is a subclass of the MogileFS::Client library, it provides a similar interface for extra functionality
provided in the FilePaths plugin.

All methods are inhereted and usable from the MogileFS::Client library, with only the exceptions listed below.

=cut

use strict;
use warnings;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

use base 'MogileFS::Client';

=head1 METHOD CHANGES

=head2 new_file

The fourth argument to the new_file method is a hashref of options for this transaction. This module handles a new
option called 'meta' which is metadata to be stored along with the file in mogilefs. For example:

 $filehandle = $mogc->new_file($path, $class, $size, {
     meta => {
         mtime => scalar(time),
         foo => "bar",
     },
 });

=cut

sub new_file {
    my $self = shift;
    my ($path, $class, $size, $opts) = @_;

    $opts ||= {};
    my $cc_args = ($opts->{create_close_args} ||= {});

    if (exists $opts->{meta}) {
        my $meta = $opts->{meta};
        my $keycount = 0;
        while (my ($key, $value) = each %$meta) {
            $cc_args->{"plugin.meta.key$keycount"}   = $key;
            $cc_args->{"plugin.meta.value$keycount"} = $value;
            $keycount++;
        }
        $cc_args->{"plugin.meta.keys"} = $keycount;
    }

    $self->SUPER::new_file($path, $class, $size, $opts);
}

=head1 NEW METHODS

=head2 list

 @files = $mogc->list($path)

 Given a path, returns a list of files contained in that path. Each element of the returned list is a hashref with the following possible keys:

=over

=item name

Contains the name of the file

=item path

Contains the fully qualified path of the file

=item is_directory

True if item is a directory

=item is_file

True if item is a file

=item modified

Value of mtime metadata field stored with this file.

=item size

Size in bytes for this file.

=back

=cut

sub list {
    my $self = shift;
    my $path = shift;
    return unless defined $path && length $path;
    my $dir = $self->SUPER::filepaths_list_directory($path);
    return unless $dir;

    $path =~ s!/?$!/!; # Make sure there's a / on the end of the path

    my $filecount = $dir->{files};
    return unless $filecount and $filecount > 0;

    my @ret;

    for (my $i = 0; $i < $filecount; $i++) {
        my $prefix = "file$i";
        my %nodeinfo;

        my $name = $nodeinfo{name} = $dir->{$prefix};
        $nodeinfo{path} = $path . $name;
        if ($dir->{"$prefix.type"} eq 'D') {
            $nodeinfo{is_directory} = 1;
        } else {
            $nodeinfo{is_file} = 1;
            my $mtime = $dir->{"$prefix.mtime"};
            $nodeinfo{modified} = $mtime if $mtime;
            $nodeinfo{size} = $dir->{"$prefix.size"};
        }

        push @ret, \%nodeinfo;
    }

    return @ret;
}

=head2 rename

 $rv = $mogc->rename($oldpath, $newpath)

Attempts to rename $oldpath to $newpath, returns true on success and false on failure.

=cut

sub rename {
    my $self = shift;
    my $orig_path = shift;
    my $new_path = shift;

    my $result = $self->SUPER::filepaths_rename($orig_path, $new_path);

    return 1 if $result;
    return;
}

1;
