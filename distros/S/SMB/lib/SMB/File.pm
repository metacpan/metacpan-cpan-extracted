# SMB-Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB::File;

use strict;
use warnings;

use parent 'SMB';

use Time::HiRes qw(stat);
use File::Basename qw(basename);
use File::Glob qw(bsd_glob GLOB_NOCASE GLOB_BRACE);
use Fcntl qw(:mode O_DIRECTORY O_RDONLY O_RDWR O_CREAT O_EXCL O_TRUNC);
use POSIX qw(strftime);

use SMB::Time qw(from_nttime to_nttime);

use constant {
	ATTR_READONLY            => 0x00000001,
	ATTR_HIDDEN              => 0x00000002,
	ATTR_SYSTEM              => 0x00000004,
	ATTR_DIRECTORY           => 0x00000010,
	ATTR_ARCHIVE             => 0x00000020,
	ATTR_DEVICE              => 0x00000040,
	ATTR_NORMAL              => 0x00000080,
	ATTR_TEMPORARY           => 0x00000100,
	ATTR_SPARSE_FILE         => 0x00000200,
	ATTR_REPARSE_POINT       => 0x00000400,
	ATTR_COMPRESSED          => 0x00000800,
	ATTR_OFFLINE             => 0x00001000,
	ATTR_NOT_CONTENT_INDEXED => 0x00002000,
	ATTR_ENCRYPTED           => 0x00004000,

	DISPOSITION_SUPERSEDE    => 0,  # exists ? supersede : create
	DISPOSITION_OPEN         => 1,  # exists ? open      : fail
	DISPOSITION_CREATE       => 2,  # exists ? fail      : create
	DISPOSITION_OPEN_IF      => 3,  # exists ? open      : create
	DISPOSITION_OVERWRITE    => 4,  # exists ? overwrite : fail
	DISPOSITION_OVERWRITE_IF => 5,  # exists ? overwrite : create

	ACTION_NONE        => -1,
	ACTION_SUPERSEDED  => 0,  # existing file was deleted and new file was created in its place
	ACTION_OPENED      => 1,  # existing file was opened
	ACTION_CREATED     => 2,  # new file was created
	ACTION_OVERWRITTEN => 3,  # new file was overwritten
};

use SMB::OpenFile;

sub from_ntattr ($) {
	my $attr = shift || 0;

	return
		$attr & ATTR_DIRECTORY ? O_DIRECTORY :
		$attr & ATTR_READONLY ? O_RDONLY : O_RDWR;
}

sub to_ntattr ($) {
	my $mode = shift || 0;

	return 0
		| (S_ISREG($mode) ? ATTR_NORMAL    : 0)
		| (S_ISDIR($mode) ? ATTR_DIRECTORY : 0)
#		| (S_ISBLK($mode) ? ATTR_DEVICE    : 0)
		| (S_ISCHR($mode) ? ATTR_DEVICE    : 0)
		| ($mode & S_IWUSR ? 0 : ATTR_READONLY)
		;
}

sub new ($%) {
	my $class = shift;
	my %options = @_;

	my $name = delete $options{name} // die "No name in constructor";
	$name =~ s!\\!\/!g;
	$name =~ s!/{2,}!/!g;
	$name =~ s!/$!!;
	my $is_directory = delete $options{is_directory};
	my $root = $options{share_root} //= undef;
	my $filename = undef;
	if ($root) {
		die "No share_root directory ($root)" unless -d $root;
		while ($root =~ s=(^|/)(?!\.\./)[^/]+/\.\./=$1=) {}
		$filename = $name eq '' ? $root : "$root/$name";
		$filename =~ s!/{2,}!/!g;
		$filename = '.' if $filename eq '';
	}
	my $is_ipc = $options{is_ipc} ||= 0;
	my @stat = !$is_ipc && $filename && -e $filename ? stat($filename) : ();
	my $is_srv = $is_ipc && $name =~ /^(?:srvsvc|wkssvc)$/;

	my $self = $class->SUPER::new(
		name             => $name,
		filename         => $filename,  # server-side file only
		creation_time    => @stat ? to_nttime($stat[10])  : 0,
		last_access_time => @stat ? to_nttime($stat[ 8])  : 0,
		last_write_time  => @stat ? to_nttime($stat[ 9])  : 0,
		change_time      => @stat ? to_nttime($stat[ 9])  : 0,
		allocation_size  => @stat ? ($stat[12] || 0) * 512: 0,
		end_of_file      => @stat ? $stat[ 7]             : 0,
		attributes       => @stat ? to_ntattr($stat[ 2])  : $is_directory ? ATTR_DIRECTORY : 0,
		exists           => @stat || $is_srv ? 1 : 0,
		opens            => 0,
		%options,
	);

	return $self;
}

sub update ($$$$$$$$;$) {
	my $self = shift;

	$self->creation_time(shift);
	$self->last_access_time(shift);
	$self->last_write_time(shift);
	$self->change_time(shift);
	my $size1 = shift;
	my $size2 = shift;
	$self->attributes(shift);
	my $is_eof_first = shift;
	$self->allocation_size($is_eof_first ? $size2 : $size1);
	$self->end_of_file    ($is_eof_first ? $size1 : $size2);

	$self->exists($self->creation_time ? 1 : 0);
}

sub is_directory ($) {
	my $self = shift;

	return $self->is_ipc ? 0 : $self->attributes & ATTR_DIRECTORY ? 1 : 0;
}

sub time_to_string ($;$) {
	my $time = shift;
	my $format = shift || "%4Y-%2m-%2d %2H:%2M";

	return strftime($format, localtime $time);
}

sub ctime { from_nttime($_[0]->creation_time) }
sub atime { from_nttime($_[0]->last_access_time) }
sub wtime { from_nttime($_[0]->last_write_time) }
sub mtime { from_nttime($_[0]->change_time) }
sub ctime_string { time_to_string($_[0]->ctime, $_[1]) }
sub atime_string { time_to_string($_[0]->atime, $_[1]) }
sub wtime_string { time_to_string($_[0]->wtime, $_[1]) }
sub mtime_string { time_to_string($_[0]->mtime, $_[1]) }

sub add_openfile ($$$) {
	my $self = shift;
	my $handle = shift;
	my $action = shift;

	my $openfile = SMB::OpenFile->new($self, $handle, $action);

	$self->{opens}++;
	$self->exists(1);

	return $openfile;
}

sub delete_openfile ($$) {
	my $self = shift;
	my $openfile = shift;

	close($openfile->handle)
		if $openfile->handle;

	--$self->{opens};
}

sub _fail_exists ($$) {
	my $self = shift;
	my $exists = shift;

	$self->err("Can't open file [$self->{filename}]: $!");
	$self->exists($exists || 0);

	return undef;
}

sub supersede ($) {
	my $self = shift;

	return $self->create unless -e $self->filename;

	my $filename = $self->filename;
	my $tmp_filename = sprintf "%s.%06d", $self->filename, rand(1000000);

	rename($filename, $tmp_filename)
		or return $self->_fail_exists(1);
	my $openfile = $self->create;
	unless ($openfile) {
		rename($tmp_filename, $filename)
			or $self->err("Can't rename tmp file ($tmp_filename) to orig file ($filename)");
		return $self->_fail_exists(0);
	}
	unlink($tmp_filename)
		or $self->err("Can't remove tmp file ($tmp_filename)");

	$openfile->action(ACTION_SUPERSEDED);

	return $openfile;
}

sub open ($) {
	my $self = shift;

	sysopen(my $fh, $self->filename, from_ntattr($self->attributes))
		or return $self->_fail_exists(0);

	$self->add_openfile($fh, ACTION_OPENED);
}

sub create ($) {
	my $self = shift;

	sysopen(my $fh, $self->filename, from_ntattr($self->attributes) | O_CREAT | O_EXCL)
		or return $self->_fail_exists(-e $self->filename ? 1 : 0);

	$self->add_openfile($fh, ACTION_CREATED);
}

sub overwrite ($) {
	my $self = shift;

	# no idea why O_TRUNC fails on Windows
	my $mode = $^O eq 'MSWin32' ? 0 : O_TRUNC;

	sysopen(my $fh, $self->filename, from_ntattr($self->attributes) | $mode)
		or return $self->_fail_exists(0);

	truncate($fh, 0) if $^O eq 'MSWin32';

	$self->add_openfile($fh, ACTION_OVERWRITTEN);
}

sub open_if ($) {
	my $self = shift;

	return -e $self->filename ? $self->open : $self->create;
}

sub overwrite_if ($) {
	my $self = shift;

	return -e $self->filename ? $self->overwrite : $self->create;
}

sub open_by_disposition ($$) {
	my $self = shift;
	my $disposition = shift;

	return $self->add_openfile(undef, ACTION_OPENED)
		if $self->is_ipc;

	return $self->supersede    if $disposition == DISPOSITION_SUPERSEDE;
	return $self->open         if $disposition == DISPOSITION_OPEN;
	return $self->create       if $disposition == DISPOSITION_CREATE;
	return $self->open_if      if $disposition == DISPOSITION_OPEN_IF;
	return $self->overwrite    if $disposition == DISPOSITION_OVERWRITE;
	return $self->overwrite_if if $disposition == DISPOSITION_OVERWRITE_IF;

	warn "Invalid disposition $disposition, can not open file\n";
	return;
}

sub normalize_name_in_share ($$) {
	my $self = shift;
	my $name = shift // die "Missing file name to normalize in share\n";

	my $root = $self->share_root;
	return unless $root;

	$name =~ s=\\=\/=g;
	$name =~ s=/{2,}=/=g;
	$name =~ s=^/|/$==;
	$name =~ s=(^|/)\.(/|$)=$1=g;
	while ($name =~ s=(^|/)(?!\.\./)[^/]+/\.\./=$1=) {}

	# refuse to go below the root
	return if $name =~ m=^\.\.?(/|$)=;

	return $name eq '' ? $root : "$root/$name";
}

sub find_files ($%) {
	my $self = shift;
	my %params = @_;

	return unless $self->is_directory;

	my $pattern = $params{pattern} || '*';
	my $want_all = $pattern eq '*';
	my $start_idx = $params{start_idx} || 0;
	my $files = $self->{files};  # cached for fragmented queries
	my $name = $self->name;

	# fix pattern if needed
	my $pattern0 = $pattern;
	$pattern0 =~ s/^\*/{.*,*}/;

	if (!$files || $start_idx == 0) {
		my @filenames = map { -e $_ && basename($_) } bsd_glob($self->filename . "/$pattern0", GLOB_NOCASE | GLOB_BRACE);
		$self->msg("Find [$self->{filename}/$pattern] - " . scalar(@filenames) . " files");
		$files = [ map { SMB::File->new(
			name => $name eq '' ? $_ : "$name/$_",
			share_root => $self->share_root,
		) } @filenames ];
		$self->{files} = $files if $want_all;
	}

	return $start_idx ? [ @{$files}[$start_idx .. (@$files - 1)] ] : $files;
}

sub remove ($) {
	my $self = shift;

	if ($self->is_directory) {
		rmdir($self->filename);
	} else {
		unlink($self->filename);
	}

	return $! == 0;
}

sub rename ($$;$) {
	my $self = shift;
	my $new_filename = shift // die "Missing new filename to rename\n";
	my $replace = shift // 0;

	my $filename = $self->filename;

	return (SMB::STATUS_OBJECT_NAME_NOT_FOUND, "Bad name [$new_filename]")
		unless $new_filename = $self->normalize_name_in_share($new_filename);
	return (SMB::STATUS_NO_SUCH_FILE, "No such file $filename")
		unless -e $filename;
	return (SMB::STATUS_SHARING_VIOLATION, "New name can't be existing directory")
		if -d $new_filename;
	return (SMB::STATUS_OBJECT_NAME_COLLISION, "Already exists")
		if !$replace && -e $new_filename;

	return (SMB::STATUS_ACCESS_DENIED, "Failed to rename")
		unless rename($self->filename, $new_filename);

	return (SMB::STATUS_SUCCESS);
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::File - Remote or local file abstraction for SMB

=head1 SYNOPSIS

	use SMB::File;

	# create local file object for server
	my $file = SMB::File->new(
		name => $create_request->file_name,
		share_root => $tree->root,
		is_ipc => $tree->is_ipc,
	);
	say $file->name;      # "john\\file.txt"
	say $file->filename;  # "/my/shares/Users/john/file.txt"


	# acquire remote file object(s) for client
	my $file = $create_response->openfile->file;
	my @files = @{$querydirectory_response->files};

=head1 DESCRIPTION

This class implements an SMB file abstraction for a client or a server.

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 CONSTANTS

The following constants are available as SMB::File::CONSTANT_NAME.

	ATTR_READONLY
	ATTR_HIDDEN
	ATTR_SYSTEM
	ATTR_DIRECTORY
	ATTR_ARCHIVE
	ATTR_DEVICE
	ATTR_NORMAL
	ATTR_TEMPORARY
	ATTR_SPARSE_FILE
	ATTR_REPARSE_POINT
	ATTR_COMPRESSED
	ATTR_OFFLINE
	ATTR_NOT_CONTENT_INDEXED
	ATTR_ENCRYPTED

	DISPOSITION_SUPERSEDE
	DISPOSITION_OPEN
	DISPOSITION_CREATE
	DISPOSITION_OPEN_IF
	DISPOSITION_OVERWRITE
	DISPOSITION_OVERWRITE_IF

	ACTION_NONE
	ACTION_SUPERSEDED
	ACTION_OPENED
	ACTION_CREATED
	ACTION_OVERWRITTEN

=head1 METHODS

=over 4

=item new [OPTIONS]

Class constructor. Creates an instance of SMB::File.

The following keys of OPTIONS hash are recognized in addition to the ones
recognized by superclass L<SMB>:

	name          SMB name, no need to start with a backslash
	is_directory  for remote file, this is an attribute hint
	share_root    for local file, this is the share directory
	is_ipc        for local or remote file in IPC tree

=item update CREATION_TIME LAST_ACCESS_TIME LAST_WRITE_TIME CHANGE_TIME ALLOCATION_SIZE END_OF_FILE ATTRIBUTES [SWAPPED=0]

Updates corresponding file times (each uint64), sizes (each uint64) and
attributes (uint32). Flag SWAPPED indicates that the sizes are swapped
(first end_of_file, then allocation_size).

=item is_directory

Returns true when the file is marked or stat'd as a directory.

=item ctime

Returns file creation_time as unix time.

=item atime

Returns file last_access_time as unix time.

=item wtime

Returns file last_write_time as unix time.

=item mtime

Returns file change_time as unix time.

=item ctime_string [FORMAT]

Returns file creation_time as string using function B<time_to_string>.

=item atime_string [FORMAT]

Returns file last_access_time as string using function B<time_to_string>.

=item wtime_string [FORMAT]

Returns file last_write_time as string using function B<time_to_string>.

=item mtime_string [FORMAT]

Returns file change_time as string using function B<time_to_string>.

=item add_openfile HANDLE ACTION

Create and return an L<SMB::OpenFile> object using supplied HANDLE and
ACTION, intended for local files on server side. HANDLE may be undef for
special open files (like IPC files I<srvsvc> and I<wkssvc>). Increments
the number of open files for this file object.

=item delete_openfile OPENFILE

The opposite of B<add_openfile>, closes handle if needed and decrements
the number of open files for this file object.

=item supersede

=item open

=item create

=item overwrite

=item open_if

=item overwrite_if

=item open_by_disposition DISPOSITION

Opens local file by given disposition (using NTFS / SMB semantics).
Returns an L<SMB::OpenFile> object on success or undef on failure.
The openfile object is created by calling B<add_openfile> internally.

=item find_files PARAMS

Returns an array ref of L<SMB::File> objects corresponding to the files
in this local file object that is a directory. PARAMS is a hash with
optional keys "pattern" (default "*") and "start_idx" (default 0).

=back

=head1 FUNCTIONS

None of the following functions are exported. But they may be called as
SMB::File::FUNC_NAME.

=over 4

=item from_ntattr NTFS_ATTR

Converts from NTFS attributes (uint32) to Unix mode (unsigned int).

=item to_ntattr UNIX_MODE

Converts from Unix mode (unsigned int) to NTFS attributes (uint32).

=item time_to_string TIME [FORMAT="%4Y-%2m-%2d %2H:%2M"]

Returns human readable representation of unix time (uint32).

=back

=head1 SEE ALSO

L<SMB::OpenFile>, L<SMB::Tree>, L<SMB::Client>, L<SMB::Server>, L<SMB>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>

