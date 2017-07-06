package Net::MythTV::Fuse;

=head1 NAME

Net::MythTV::Fuse - Mount Fuse filesystem to display TV recordings managed by a MythTV backend

=head1 SYNOPSIS

 $filesystem = Net::MythTV::Fuse->new(
        mountpoint      => '/tmp/mythtv',
        backend         => 'mythbackend.domain.org',
       );

 $filesystem->run();

=head1 DESCRIPTION

This module uses Fuse to mount a virtual filesystem representing the TV
recordings captured by a local or remote MythTV backend
(www.mythtv.org). The backend must be at version 0.25 or higher.

Typically you will be using the frontend script, mythfs.pl rather than
this module directly.

=head1 METHODS

=cut


use strict;
use warnings;
use Net::MythTV::Fuse::Recordings;
use Fuse 'fuse_get_context';
use POSIX qw(ENOENT EISDIR ENOTDIR ENOTEMPTY EINVAL ECONNABORTED EACCES EIO);
use Data::Dumper 'Dumper'; # for DEBUGGING!
use Carp 'croak';

use constant MARKER_FILE=> '.fuse-mythfs';
use constant STATUS_FILE=> 'STATUS';
use constant UPCOMING_FILE=> 'UPCOMING';

our $VERSION = '1.36';

my $Package = __PACKAGE__;
my ($Recorded,$Options);

=head2 $f = Net::MythTV::Fuse->new(@options)

Create a new Fuse filesystem object according to the options. The
options are a set of key/value pairs and can be one or more of the
following:

    mountpoint           Mountpoint for the Fuse filesystem. Required and no default.
    backend              IP address of the backend (localhost)
    port                 Control port for the backend (6544)
    debug                Enable debugging if true (numeric; increasing values increase verbosity)
    threaded             Enable threading if true (true)
    fuse_options         Comma-delimited set of mount options to pass to Fuse, such as "allow_other" (none)
    cachetime            Time, in seconds, to cache list of recordings before refreshing from backend (300)
    pattern              Template for transforming recordings into paths (%T/%S)
    delimiter            Trim this string from the pathname if it is dangling or occurs multiple times (none)
    localmount           If storage group is locally (or NFS) mounted, use this mount point for direct access (none)
    dummy_data_path      Path to an XML-formatted list of recordings, used for debugging (none)

See the help text for mythfs.pl for more information on these arguments.

=cut

sub new {
    my $self     = shift;
    my %options  = @_;
    $options{mountpoint} && $options{backend}
        or croak "Usage: $self->new(mountpoint=>'\$mtpt',backend=>'\$backend,\@other_options)";

    my $recordings = Net::MythTV::Fuse::Recordings->new(\%options);
    $recordings->load_dummy_data($options{dummy_data_path})
	               if $options{dummy_data_path};

    return bless { options    => \%options,
		   recordings => $recordings
                 },ref $self || $self;
}

=head2 Read-only Accessors

The following are read-only accessors that return information about
the filesystem options:

 recordings     A Net::MythTV::Fuse::Recordings object used to fetch the recording list
 options        Hashref of options passed during object creation
 debug          Debug flag
 mountpoint     Virtual filesystem mount point
 localmount     Local mountpoint for recordings, if any
 threaded       True if threading enabled
 marker_file    Name of an automatically generated file (".fuse-mythfs") that will appear
                     at the top level of the virtual filesystem.

=cut

sub recordings {shift->{recordings}}
sub options    {shift->{options}}
sub debug      {shift->{options}{debug}}
sub mountpoint {shift->{options}{mountpoint}}
sub localmount {shift->{options}{localmount}}
sub threaded   {shift->{options}{threaded}}
sub marker_file { return MARKER_FILE }

=head2 $f->run()

This method will create the virtual filesystem and will not return
until the process is either killed, or the filesystem is unmounted
with fusermount -u.

=cut

sub run {
    my $self    = shift;
    my $options = $self->options;

    # copy critical parameters into package globals so that Fuse callbacks work
    $Recorded   = $self->recordings;
    $Options    = $options;

    $self->recordings->start_update_thread;
    
    Fuse::main(mountpoint => $options->{mountpoint},
	       getdir     => "$Package\:\:e_getdir",
	       getattr    => "$Package\:\:e_getattr",
	       open       => "$Package\:\:e_open",
	       unlink     => "$Package\:\:e_unlink",
	       rmdir      => "$Package\:\:e_rmdir",
	       read       => "$Package\:\:e_read",
	       release    => "$Package\:\:e_release",
	       readlink   => "$Package\:\:e_readlink",
	       mountopts  => $options->{fuse_options}||'',
	       debug      => $self->debug > 1,
	       threaded   => $self->threaded,
	);
}


=head2 Non-object methods

The following are ordinary subroutines that are used by Fuse to
generate the virtual filesystem:

 $clean_path = fixup($path)                Remove the leading '/' from file paths.
 $status     = e_open($path)               Check that $path can be opened and return 0 if so.
 $status     = e_release($path)            Called to release a closed path, returns 0 if successful.
 $contents   = e_read($path,$size,$offset) Called to read $size bytes from $path starting at $offset.
 @entries    = e_getdir($path)             Return all entries within directory indicated by $path.
 $contents   = e_readlink($path)           Resolve a symbolic link (used when recordings mounted locally).
 @attributes = e_getattr($path)            Stat() call on $path
 $status     = e_unlink($path)             Called to remove a file, returns 0 if successful.
 $status     = e_rmdir($path)              Called to remove a directory, returns 0 if successful.
 $string     = copyright_and_version()     Return contents of the automatic file ".fuse-mythfs"

=cut

sub fixup {
    my $path = shift;
    $path =~ s!^/!!;
    $path;
}

sub e_open {
    my $path = fixup(shift);

    # awkward: fix
    return 0 if $path eq MARKER_FILE or $path eq STATUS_FILE or $path eq UPCOMING_FILE;
    
    $Recorded->valid_path($path) or return -ENOENT();
    $Recorded->is_dir($path)    and return -EISDIR();
    return 0;
}

sub e_release {
    return 0;
}

sub e_unlink {
    my $path   = fixup(shift);

    $Recorded->valid_path($path) or return -ENOENT();
    $Recorded->is_dir($path)    and return -EISDIR();
    return -EACCES() if $path eq MARKER_FILE or $path eq STATUS_FILE or $path eq UPCOMING_FILE;   

    my $status = $Recorded->delete_recording($path);
    $status eq 'ok' or return -EIO();
    return 0;
}

sub e_rmdir {
    my $path   = fixup(shift);
    $Recorded->valid_path($path) or return -ENOENT();
    $Recorded->is_dir($path)     or return -ENOTDIR();
    my $status = $Recorded->delete_directory($path);
    $status eq 'directory not empty' and return -ENOTEMPTY();
    $status eq 'ok' or return -EIO();
    return 0;
}

sub e_read {
    my ($path,$size,$offset) = @_;
    $offset ||= 0;
    $path = fixup($path);

    # we need to create a special method for these special files
    if ($path eq MARKER_FILE) {
	my $content = copyright_and_version();
	return substr($content,$offset,$size);
    }

    if ($path eq STATUS_FILE) {
	my $content = $Recorded->status;
	return substr($content,$offset,$size);
    }

    if ($path eq UPCOMING_FILE) {
	my $content = _get_upcoming_list();
	return substr($content,$offset,$size);
    }

    my ($retcode,$contents) = $Recorded->download_recorded_file($path,$size,$offset);
    return -ENOENT()       if $retcode eq 'not found';
    return -EINVAL()       if $retcode eq 'invalid offset';
    return -ECONNABORTED() if $retcode eq 'connection failed';
    return $contents;
}

sub e_getdir {
    my $path = fixup(shift) || '.';

    my @entries = $Recorded->entries($path);
    unshift @entries,MARKER_FILE,STATUS_FILE,UPCOMING_FILE if $path eq '.';
    return -ENOENT() unless @entries;
    return ('.','..',@entries,0);
}

sub e_readlink {
    my $path = fixup(shift) || '.';
    my $basename   = $Recorded->basename($path) or return -ENOENT();
    my $localmount = $Recorded->localmount      or return -ENOENT();
    my $local_path = "$localmount/$basename";
    return $local_path;
}

sub e_getattr {
    my $path = fixup(shift) || '.';

    my $context = fuse_get_context();
    my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) 
	= (0,0,0,1,@{$context}{'gid','uid'},1,1024);

    if ($path eq MARKER_FILE) { # special case
	my $contents = copyright_and_version();
	return (
	    $dev,$ino,0100000|0444,$nlink,$uid,$gid,$rdev,
	    length($contents),time(),time(),time(),$blksize,$blocks);
    }

    if ($path eq STATUS_FILE) { # another special case
	my $contents = $Recorded->status;
	return (
	    $dev,$ino,0100000|0444,$nlink,$uid,$gid,$rdev,
	    length($contents),time(),time(),time(),$blksize,$blocks);
    }

    if ($path eq UPCOMING_FILE) { # another special case
	my $content = _get_upcoming_list();
	return (
	    $dev,$ino,0100000|0444,$nlink,$uid,$gid,$rdev,
	    length($content),time(),time(),time(),$blksize,$blocks);
    }

    my $entry    = $Recorded->entry($path) or return -ENOENT();

    # debugging an occasional error
    unless ($entry->{type}) {
	warn "broken entry for path =$path";
	print STDERR Data::Dumper::Dumper($entry);
	return -ENOENT();
    }

    my $basename = $entry->{basename};
    my $isdir    = $entry->{type} eq 'directory';
    my $islink   = $entry->{type} eq 'file' && $Recorded->localmount && -r $Recorded->localmount."/$basename";

    my $readonly = $Options->{fuse_options}=~ /\bro\b/;
    my $write = $readonly ? 0000                : 0200;
    my $mode  = $isdir    ? 0040000|0555|$write : ($islink ? 0120000|0777 : 0100000|0444|$write);

    my $ctime = $entry->{ctime};
    my $mtime = $entry->{mtime};
    my $atime = $mtime;
    my $size  = $entry->{length};

    return ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
	    $size,$atime,$mtime,$ctime,$blksize,$blocks);
}

sub copyright_and_version {
    return <<END;
mythfs.pl version $VERSION. 
Copyright 2013 Lincoln D. Stein <lincoln.stein\@gmail.com>. 
Distributed under Perl Artistic License Version 2.
END
}

sub _get_upcoming_list {
    my $self = shift;
    return $Recorded->get_upcoming_list;
}


1;


=head1 AUTHOR

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

=head1 LICENSE

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

=cut

__END__
