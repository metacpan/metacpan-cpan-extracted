package SPVM::Sys::IO;

1;

=head1 Name

SPVM::Sys::IO - IO System Call

=head1 Usage
  
  use Sys::IO;

=head1 Description

C<Sys::IO> is the class for the file IO.

=head1 Class Methods

=head2 open

  static method open : int ($path : string, $flags : int, $mode = 0 : int);

Given a pathname for a file, open() returns a file descriptor, a small, nonnegative integer for use in subsequent system calls (read(2), write(2), lseek(2), fcntl(2), etc.). The file descriptor returned by a successful call will be the lowest-numbered file descriptor not currently open for the process.

See the L<open|https://linux.die.net/man/2/open> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the flags and the mode.

=head2 read

  static method read : int ($fd : int, $buf : mutable string, $count : int, $buf_offset = 0 : int);

read() attempts to read up to count bytes from file descriptor fd into the buf starting at buf + buf_offset.

See the L<read|https://linux.die.net/man/2/read> function in Linux.

=head2 write

  static method write : int ($fd : int, $buf : string, $count : int, $buf_offset = 0 : int);

write() writes up to count bytes from the buf pointed buf + buf_offset to the file referred to by the file descriptor fd.

See the L<write|https://linux.die.net/man/2/write> function in Linux.

=head2 lseek

  static method lseek : long ($fd : int, $offset : long, $whence : int);

The lseek() function repositions the offset of the open file associated with the file descriptor fd to the argument offset according to the directive whence as follows:

See the L<lseek|https://linux.die.net/man/2/lseek> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the whence.

=head2 close

  static method close : int ($fd : int);

close() closes a file descriptor, so that it no longer refers to any file and may be reused. Any record locks (see fcntl(2)) held on the file it was associated with, and owned by the process, are removed (regardless of the file descriptor that was used to obtain the lock).

See the L<close|https://linux.die.net/man/2/close> function in Linux.

=head2 fopen

  static method fopen : Sys::IO::FileStream ($path : string, $mode : string);

The fopen() function opens the file whose name is the string pointed to by path and associates a stream with it.

See the L<fopen|https://linux.die.net/man/3/fopen> function in Linux.

The return value is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fdopen

  static method fdopen : Sys::IO::FileStream ($fd : int, $mode : string);

The fdopen() function associates a stream with the existing file descriptor, fd. The mode of the stream (one of the values "r", "r+", "w", "w+", "a", "a+") must be compatible with the mode of the file descriptor. The file position indicator of the new stream is set to that belonging to fd, and the error and end-of-file indicators are cleared. Modes "w" or "w+" do not cause truncation of the file. The file descriptor is not dup'ed, and will be closed when the stream created by fdopen() is closed. The result of applying fdopen() to a shared memory object is undefined.

See the L<fdopen|https://linux.die.net/man/3/fdopen> function in Linux.

The return value is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fileno

  static method fileno : int ($stream : Sys::IO::FileStream);

The function fileno() examines the argument stream and returns its integer descriptor.

See the L<fileno|https://linux.die.net/man/3/fileno> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fread

  static method fread : int ($ptr : mutable string, $size : int, $nmemb : int, $stream : Sys::IO::FileStream, $ptr_offset = 0 : int);

The function fread() reads nmemb elements of data, each size bytes long, from the stream pointed to by stream, storing them at the location given by ptr + ptr_offset.

See the L<fread|https://linux.die.net/man/3/fread> function in Linux.

=head2 feof

  static method feof : int ($stream : Sys::IO::FileStream);

The function feof() tests the end-of-file indicator for the stream pointed to by stream, returning nonzero if it is set. The end-of-file indicator can only be cleared by the function clearerr().

See the L<feof|https://linux.die.net/man/3/feof> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 ferror

  static method ferror : int ($stream : Sys::IO::FileStream);

The function ferror() tests the error indicator for the stream pointed to by stream, returning nonzero if it is set. The error indicator can only be reset by the clearerr() function.

See the L<ferror|https://linux.die.net/man/3/ferror> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 clearerr

  static method clearerr : void ($stream : Sys::IO::FileStream);

The function clearerr() clears the end-of-file and error indicators for the stream pointed to by stream.

See the L<clearerr|https://linux.die.net/man/3/clearerr> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 getc

  static method getc : int ($stream : Sys::IO::FileStream);

getc() is equivalent to fgetc() except that it may be implemented as a macro which evaluates stream more than once.

See the L<getc|https://linux.die.net/man/3/getc> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fgets

  static method fgets : mutable string ($s : mutable string, $size : int, $stream : Sys::IO::FileStream, $s_offset = 0 : int);

fgets() reads in at most one less than size characters from stream and stores them into the buf pointed to by s + s_offset. Reading stops after an EOF or a newline. If a newline is read, it is stored into the buf. A terminating null byte (aq\0aq) is stored after the last character in the buf.

See the L<fgets|https://linux.die.net/man/3/fgets> function in Linux.

=head2 fwrite

  static method fwrite : int ($ptr : string, $size : int, $nmemb : int, $stream : Sys::IO::FileStream, $ptr_offset = 0 : int);

The function fwrite() writes nmemb elements of data, each size bytes long, to the stream pointed to by stream, obtaining them from the location given by ptr + ptr_offset.

See the L<fread|https://linux.die.net/man/3/fwrite> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fseek

  static method fseek : int ($stream : Sys::IO::FileStream, $offset : long, $whence : int);

The fseek() function sets the file position indicator for the stream pointed to by stream. The new position, measured in bytes, is obtained by adding offset bytes to the position specified by whence. If whence is set to SEEK_SET, SEEK_CUR, or SEEK_END, the offset is relative to the start of the file, the current position indicator, or end-of-file, respectively. A successful call to the fseek() function clears the end-of-file indicator for the stream and undoes any effects of the ungetc(3) function on the same stream.

See the L<fseek|https://linux.die.net/man/3/fseek> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the whence.

=head2 ftell

  static method ftell : long ($stream : Sys::IO::FileStream);

The ftell() function obtains the current value of the file position indicator for the stream pointed to by stream.

See the L<ftell|https://linux.die.net/man/3/ftell> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fclose

  static method fclose : int ($stream : Sys::IO::FileStream);

The fclose() function flushes the stream pointed to by fp (writing any bufed output data using fflush(3)) and closes the underlying file descriptor.

See the L<fclose|https://linux.die.net/man/3/fclose> function in Linux.

The file stream is a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object.

=head2 fflush

  static method fflush : int ($stream : Sys::IO::FileStream);

For output streams, fflush() forces a write of all user-space bufed data for the given output or update stream via the stream's underlying write function. For input streams, fflush() discards any bufed data that has been fetched from the underlying file, but has not been consumed by the application. The open status of the stream is unaffected.

See the L<fflush|https://linux.die.net/man/3/fflush> function in Linux.

=head2 flock

  static method flock : int ($fd : int, $operation : int);

Apply or remove an advisory lock on the open file specified by fd. The argument operation is one of the following:

See the L<flock|https://linux.die.net/man/2/flock> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the operation.

=head2 mkdir

  static method mkdir : int ($path : string, $mode : int);

mkdir() attempts to create a directory named pathname.

See the L<mkdir|https://linux.die.net/man/2/mkdir> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the mode.

=head2 umask

  static method umask : int ($mode : int);

umask() sets the calling process's file mode creation mask (umask) to mask & 0777 (i.e., only the file permission bits of mask are used), and returns the previous value of the mask.

See the L<umask|https://linux.die.net/man/2/umask> function in Linux.

=head2 rmdir

  static method rmdir : int ($path : string);

rmdir() deletes a directory, which must be empty.

See the L<rmdir|https://linux.die.net/man/2/rmdir> function in Linux.

=head2 unlink

  static method unlink : int ($pathname : string);

unlink() deletes a name from the file system. If that name was the last link to a file and no processes have the file open the file is deleted and the space it was using is made available for reuse.

See the L<unlink|https://linux.die.net/man/2/unlink> function in Linux.

=head2 rename

  static method rename : int ($oldpath : string, $newpath : string);

rename() renames a file, moving it between directories if required. Any other hard links to the file (as created using link(2)) are unaffected. Open file descriptors for oldpath are also unaffected.

See the L<rename|https://linux.die.net/man/2/rename> function in Linux.

=head2 getcwd

  static method getcwd : mutable string ($buf : mutable string, $size : int);

The getcwd() function copies an absolute pathname of the current working directory to the array pointed to by buf, which is of length size.

See the L<getcwd|https://linux.die.net/man/2/getcwd> function in Linux.

=head2 _getdcwd

  static method _getdcwd : mutable string ($drive : int, $buffer : mutable string, $maxlen : int);

Gets the full path of the current working directory on the specified drive.

See the L<_getdcwd|https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/getdcwd-wgetdcwd?view=msvc-170> function in the case of Windows.

=head2 realpath

  static method realpath : mutable string ($path : string, $resolved_path : mutable string);

realpath() expands all symbolic links and resolves references to /./, /../ and extra '/' characters in the null-terminated string named by path to produce a canonicalized absolute pathname. The resulting pathname is stored as a null-terminated string, up to a maximum of PATH_MAX bytes, in the buf pointed to by resolved_path. The resulting path will have no symbolic link, /./ or /../ components.

See the L<realpath|https://linux.die.net/man/3/realpath> function in Linux.

=head2 _fullpath

  native static method _fullpath : mutable string ($absPath : mutable string, $relPath : string, $maxLength : int);

Creates an absolute or full path name for the specified relative path name.

See the L<_fullpath|https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/fullpath-wfullpath?view=msvc-170> function in the case of Windows.

=head2 chdir

  static method chdir : int ($path : string);

chdir() changes the current working directory of the calling process to the directory specified in path.

See the L<chdir|https://linux.die.net/man/2/chdir> function in Linux.

=head2 chmod

  static method chmod : int ($path : string, $mode :int);

chmod() changes the permissions of the file specified whose pathname is given in path, which is dereferenced if it is a symbolic link.

See the L<chmod|https://linux.die.net/man/2/chmod> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the mode.

=head2 chown

  static method chown : int ($path : string, $owner : int, $group : int);

chown() changes the ownership of the file specified by path, which is dereferenced if it is a symbolic link.

See the L<chown|https://linux.die.net/man/2/chown> function in Linux.

=head2 truncate

  static method truncate : int ($path : string, $length : long);

The truncate() and ftruncate() functions cause the regular file named by path or referenced by fd to be truncated to a size of precisely length bytes.

See the L<truncate|https://linux.die.net/man/2/truncate> function in Linux.

=head2 symlink

  static method symlink : int ($oldpath : string, $newpath : string);

symlink() creates a symbolic link named newpath which contains the string oldpath.

See the L<symlink|https://linux.die.net/man/2/symlink> function in Linux.

=head2 readlink

  static method readlink : int ($path : string, $buf : mutable string, $bufsiz : int);

readlink() places the contents of the symbolic link path in the buf buf, which has size bufsiz. readlink() does not append a null byte to buf. It will truncate the contents (to a length of bufsiz characters), in case the buf is too small to hold all of the contents.

See the L<readlink|https://linux.die.net/man/2/readlink> function in Linux.

=head2 get_readlink_buffer_size

  native static method get_readlink_buffer_size : int ($path : string);

Gets the L</"readlink"> needed buffer size.

=head2 opendir

  static method opendir : Sys::IO::DirStream ($dir : string);

The opendir() function opens a directory stream corresponding to the directory name, and returns a pointer to the directory stream. The stream is positioned at the first entry in the directory.

See the L<opendir|https://linux.die.net/man/3/opendir> function in Linux.

The return value is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

=head2 closedir

  static method closedir : int ($dirp : Sys::IO::DirStream);

The closedir() function closes the directory stream associated with dirp. A successful call to closedir() also closes the underlying file descriptor associated with dirp. The directory stream descriptor dirp is not available after this call.

See the L<closedir|https://linux.die.net/man/3/closedir> function in Linux.

The directory stream is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

=head2 readdir

  static method readdir : Sys::IO::Dirent ($dirp : Sys::IO::DirStream); # Non-thead safe

The readdir() function returns a pointer to a dirent structure representing the next directory entry in the directory stream pointed to by dirp. It returns NULL on reaching the end of the directory stream or if an error occurred.

See the L<readdir|https://linux.die.net/man/3/readdir> function in Linux.

The directory stream is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

The return value is a L<Sys::IO::Dirent|SPVM::Sys::IO::Dirent> object.

=head2 rewinddir

  static method rewinddir : void ($dirp : Sys::IO::DirStream);

The rewinddir() function resets the position of the directory stream dirp to the beginning of the directory.

See the L<rewinddir|https://linux.die.net/man/3/rewinddir> function in Linux.

The directory stream is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

=head2 telldir

  static method telldir : long ($dirp : Sys::IO::DirStream);

The telldir() function returns the current location associated with the directory stream dirp.

See the L<telldir|https://linux.die.net/man/3/telldir> function in Linux.

The directory stream is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

=head2 seekdir

  static method seekdir : void ($dirp : Sys::IO::DirStream, $offset : long);

The seekdir() function sets the location in the directory stream from which the next readdir(2) call will start. seekdir() should be used with an offset returned by telldir(3).
See the L<seekdir|https://linux.die.net/man/3/seekdir> function in Linux.

The directory stream is a L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream> object.

=head2 utime

  static method utime : int ($filename : string, $times : Sys::IO::Utimbuf);

The utime() system call changes the access and modification times of the inode specified by filename to the actime and modtime fields of times respectively.

See the L<utime|https://linux.die.net/man/2/utime> function in Linux.

The buf is a L<Sys::IO::Utimbuf|SPVM::Sys::IO::Utimbuf> object.

=head2 access_raw

  static method access_raw : int ($pathname : string, $mode : int);

The same as L</"access">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 access

  static method access : int ($pathname : string, $mode : int);

access() checks whether the calling process can access the file pathname. If pathname is a symbolic link, it is dereferenced.

See the L<access|https://linux.die.net/man/2/access> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the mode.

=head2 eaccess_raw

  static method eaccess_raw : int ($pathname : string, $mode : int);

The same as L</"eaccess">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 eaccess

  static method eaccess : int ($pathname : string, $mode : int);

eaccess() checks whether the calling process can eaccess the file pathname. If pathname is a symbolic link, it is dereferenced.

See the L<eaccess|https://linux.die.net/man/3/eaccess> function in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the C<$mode>.

=head2 eaccess_raw

  static method eaccess : int ($pathname : string, $mode : int)

The same as L</"eaccess">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 eaccess

  static method eaccess : int ($pathname : string, $mode : int)

Emulates C<eaccess> using L</"faccessat">.

=head2 stat_raw

  static method stat_raw : int ($path : string, $stat : Sys::IO::Stat);

The same as L</"stat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 stat

  static method stat : int ($path : string, $stat : Sys::IO::Stat);

These functions return information about a file. No permissions are required on the file itself, but-in the case of stat() and lstat() - execute (search) permission is required on all of the directories in path that lead to the file.

stat() stats the file pointed to by path and fills in buf.

See the L<stat|https://linux.die.net/man/2/stat> function in Linux.

The stat is L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 lstat_raw

  static method lstat_raw : int ($path : string, $stat : Sys::IO::Stat);

The same as L</"lstat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 lstat

  static method lstat : int ($path : string, $stat : Sys::IO::Stat);

These functions return information about a file. No permissions are required on the file itself, but-in the case of stat() and lstat() - execute (search) permission is required on all of the directories in path that lead to the file.

lstat() is identical to stat(), except that if path is a symbolic link, then the link itself is stat-ed, not the file that it refers to.

See the L<lstat|https://linux.die.net/man/2/lstat> function in Linux.

The stat is L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 fcntl

  static method fcntl : int ($fd : int, $command : int, $command_arg = undef : object of Int|Sys::IO::Flock|object);

fcntl() performs one of the operations described below on the open file descriptor fd. The operation is determined by cmd.

See the L<lstat|https://linux.die.net/man/2/fcntl> function in Linux.

The command argument can receive a L<Sys::IO::Flock|SPVM::Sys::IO::Flock> object.

=head2 readline

  static method readline : string ($stream : Sys::IO::FileStream);

Reads characters from C<$stream> until C<\n> or C<EOF> is found and return it.

The C<$stream> must be defined. Otherwise an exception will thrown.

=head2 ftruncate

  static method ftruncate : int ($fd : int, $length : long);

The ftruncate() functions cause the regular file named by referenced by fd to be truncated to a size of precisely length bytes.

See L<ftruncate(2) - Linux man page|https://linux.die.net/man/2/ftruncate> in Linux.

=head2 ungetc

  static method ungetc : int ($c : int, $stream : Sys::IO::FileStream);

ungetc() pushes c back to stream, cast to unsigned char, where it is available for subsequent read operations. Pushed-back characters will be returned in reverse order; only one pushback is guaranteed.

See L<ungetc(3) - Linux man page|https://linux.die.net/man/3/ungetc> in Linux.

=head2 fsync

  static method fsync : int ($fd : int);

fsync() transfers ("flushes") all modified in-core data of (i.e., modified buffer cache pages for) the file referred to by the file descriptor fd to the disk device (or other permanent storage device) so that all changed information can be retrieved even after the system crashed or was rebooted.

See L<fsync(2) - Linux man page|https://linux.die.net/man/2/fsync> in Linux.

=head2 fstat_raw

  static method fstat_raw : int ($fd : int, $stat : Sys::IO::Stat);

The same as L</"fstat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 fstat

  static method fstat : int ($fd : int, $stat : Sys::IO::Stat);

fstat() is identical to stat(), except that the file to be stat-ed is specified by the file descriptor fd.

See L<fstat(2) - Linux man page|https://linux.die.net/man/2/fsync> in Linux.

The C<$stat> is a L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 freopen

  static method freopen : Sys::IO::FileStream ($path : string, $mode : string, $stream : Sys::IO::FileStream);

The freopen() function opens the file whose name is the string pointed to by path and associates the stream pointed to by stream with it.

See L<freopen(3) - Linux man page|https://linux.die.net/man/3/freopen> in Linux.

=head2 setvbuf

  static method setvbuf : int ($stream : Sys::IO::FileStream, $buf : mutable string, $mode : int, $size : int);

The setvbuf() function may be used on any open stream to change its buffer.

See L<setvbuf(3) - Linux man page|https://linux.die.net/man/3/setvbuf> in Linux.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about the constant value for the C<$mode>.

=head2 setbuf

  static method setbuf : void ($stream : Sys::IO::FileStream, $buf : mutable string);

The same as the following code using L</"setvbuf">.

    my $mode : int;
    if ($buf) {
      $mode = IO->_IOFBF;
    }
    else {
      $mode = IO->_IONBF;
    }
    
    &setvbuf($stream, $buf, $mode, IO->BUFSIZ);

=head2 setbuffer

  static method setbuffer : void ($stream : Sys::IO::FileStream, $buf : mutable string, $size : int);

The same as the following code using L</"setvbuf">.

  my $mode : int;
  if ($buf) {
    $mode = IO->_IOFBF;
  }
  else {
    $mode = IO->_IONBF;
  }
  
  &setvbuf($stream, $buf, $mode, $size);

=head2 setlinebuf

  static method setlinebuf : void ($stream : Sys::IO::FileStream);

The same as the following code using L</"setvbuf">.

  my $mode = IO->_IOLBF;
  &setvbuf($stream, undef, $mode, IO->BUFSIZ);

=head2 stdin

  static method stdin : Sys::IO::FileStream ();

Returns a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object that has the pointer to the stream that C<stdin> in C<C language> returns.

See L<stdin(3) - Linux man page|https://linux.die.net/man/3/stdin> in Linux.

=head2 stdout

  static method stdout : Sys::IO::FileStream ();

Returns a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object that has the pointer to the stream that C<stdout> in C<C language> returns.

See L<stdout(3) - Linux man page|https://linux.die.net/man/3/stdout> in Linux.

=head2 stderr

  static method stderr : Sys::IO::FileStream ();

Returns a L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> object that has the pointer to the stream that C<stderr> in C<C language> returns.

See L<stderr(3) - Linux man page|https://linux.die.net/man/3/stderr> in Linux.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

