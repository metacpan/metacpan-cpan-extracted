package SPVM::Sys;

our $VERSION = "0.514001";

1;

=head1 Name

SPVM::Sys - System Calls for File IO, Sockets, Time, Process, Signals, Users

=head1 Description

The Sys class in L<SPVM> has methods to call system calls for file IO, sockets, user manipulation, process manipulation, and time.

=head1 Usage

  use Sys;
  
  my $fd_ref = [(Sys::IO::FileStream)undef];
  Sys->open($fd_ref, "<", $path);
  
  Sys->mkdir("foo");
  
  Sys->rmdir("foo");
  
  my $path = Sys->env("PATH");
  
  my $process_id = Sys->process_id;

=head1 Class Methods

=head2 STDIN

C<static method STDIN : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> ();>

Returns the L<stdin|SPVM::Document::NativeAPI/"spvm_stdin"> opened by the SPVM language.

=head2 STDOUT

C<static method STDOUT : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> ();>

Returns the L<stdout|SPVM::Document::NativeAPI/"spvm_stdout"> opened by the SPVM language.

=head2 STDERR

C<static method STDERR : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream> ();>

Returns the L<stderr|SPVM::Document::NativeAPI/"spvm_stderr"> opened by the SPVM language.

=head2 open

C<static method open : void ($stream_ref : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>[], $open_mode : string, $file_name : string);>

Opens a file given the open mode $open_mode and the file name $file_name. 

The opened file stream is set to $stream_ref at index 0.

The open mode $open_mode is replaced to a representation of the L<fopen|https://linux.die.net/man/3/fopen> function before calling the L<fopen|https://linux.die.net/man/3/fopen> function.

  [$open_mode]   [The mode of the fopen function]
  <              rb
  >              wb
  >>             wa
  +<             r+b
  +>             w+b
  +>>            a+b

If the system supports C<FD_CLOEXEC>, this flag is set to the opened file's file descriptor using L</"fcntl">.

Exceptions:

$stream_ref must be defined. Otherwise an exception is thrown.

The length of $stream_ref must be equal to 1. Otherwise an exception is thrown.

Exceptions thrown by the L<fopen|SPVM::Sys::IO/"fopen"> method in the Sys::IO class could be thrown.

=head2 fdopen

C<static method fdopen : void ($stream_ref : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>[], $open_mode : string, $fd : int);>

Same as L</"open"> method except that this method takes the file descriptor $fd instead of the file name .

=head2 fileno

C<static method fileno : int ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Return the file descriptor of the file stream $stream.

Exceptions:

Exceptions thrown by the L<fileno|SPVM::Sys::IO/"fileno"> method in the Sys::IO class could be thrown.

=head2 read

C<static method read : int ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>, $buf : mutable string, $length : int, $buf_offset : int = 0);>

Reads data from the file stream $stream by the $length, and saves it to the buffer $buf at offset $buf_offset.

Exceptions:

Exceptions thrown by the L<fread|SPVM::Sys::IO/"fread"> method in the Sys::IO class could be thrown.

=head2 eof

C<static method eof : int ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Checks if the file stream $stream reasches the end of the file.

If it does, returns 1, otherwise returns 0.

Exceptions:

Exceptions thrown by the L<feof|SPVM::Sys::IO/"feof"> method in the Sys::IO class could be thrown.

=head2 readline

C<static method readline : mutable string ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Reads a line from th file stream $stream and returns it.

Exceptions:

$stream must be defined.

Exceptions thrown by the L</"getc"> method could be thrown.

=head2 getc

C<static method getc : int ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Gets a charactor from the file stream $stream and returns it.

Exceptions:

Exceptions thrown by the L<getc|SPVM::Sys::IO/"getc"> method in the Sys::IO class could be thrown.

=head2 print

C<static method print : void ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>, $string : string);>

Prints the string $string to the file stream $stream.

Exceptions:

Exceptions thrown by the L<fwrite|SPVM::Sys::IO/"fwrite"> method in the Sys::IO class could be thrown.

=head2 printf

C<static method printf : void ($stream, $format : string, $args : object[])>

Prints the format string $string given the arguments $args to the file stream $stream.

Exceptions thrown by the L<"print"> method class could be thrown.

=head2 say

C<static method say : void ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>, $string : string);>

Prints the string $string and "\n" to the file stream $stream.

Exceptions:

Exceptions thrown by the L<"print"> method class could be thrown.

=head2 close

C<static method close : void ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Closes the file stream $stream.

Exceptions:

Exceptions thrown by the L<fclose|SPVM::Sys::IO/"fclose"> method in the Sys::IO class could be thrown.

=head2 seek

C<static method seek : void ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>, $offset : long, $whence : int);>

Moves the read/write position pointed to by the file stream $stream to the offset $offset given $whence.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about constant values given to $whence.

Exceptions:

Exceptions thrown by the L<fseek|SPVM::Sys::IO/"fseek"> method in the Sys::IO class could be thrown.

=head2 tell

C<static method tell : long ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Returns the read/write position pointed to by the file stream $stream.

Exceptions:

Exceptions thrown by the L<ftell|SPVM::Sys::IO/"ftell"> method in the Sys::IO class could be thrown.

=head2 sysopen

C<static method sysopen : void ($fd_ref : int*, $path : string, $flags : int, $mode : int = 0);>

Opens a file given, the file path $path, the mode $flags and the mode $mode.

The file descriptor of the opened file is set to the value reffered by $fd_ref.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about constant values given to the flags $flags and the mode $mode.

Exceptions:

Exceptions thrown by the L<open|SPVM::Sys::IO/"open"> method in the Sys::IO class could be thrown.

=head2 sysread

C<static method sysread : int ($fd : int, $buf : mutable string, $length : int, $buf_offset : int = 0);>

Reads data from the file stream $stream by the $length, and saves it to the buffer $buf from the offset $buf_offset.

Exceptions:

Exceptions thrown by the L<read|SPVM::Sys::IO/"read"> method in the Sys::IO class could be thrown.

=head2 syswrite

C<static method syswrite : int ($fd : int, $buf : string, $length : int = -1, $buf_offset : int = 0);>

Writes data to the file stream $stream by the $length from the buffer $buf at offset $buf_offset.

Exceptions:

Exceptions thrown by the L<write|SPVM::Sys::IO/"write"> method in the Sys::IO class could be thrown.

=head2 sysseek

C<static method sysseek : long ($fd : int, $offset : long, $whence : int);>

Moves the read/write position pointed to by the file descriptor $fd to the offset $offset given $whence.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about constant values given to $whence.

Exceptions:

Exceptions thrown by the L<lseek|SPVM::Sys::IO/"lseek"> method in the Sys::IO class could be thrown.

=head2 fcntl

C<static method fcntl : int ($fd : int, $command : int, $command_arg : object of Int|SPVM::Sys::IO::Flock|object = undef);>

Calls the L<fcntl|SPVM::Sys::IO/"fcntl"> method in the Sys::IO class and its return value.

Exceptions:

Exceptions thrown by the L<fcntl|SPVM::Sys::IO/"fcntl"> method in the Sys::IO class could be thrown.

=head2 flock

C<static method flock : void ($fd : int, $operation : int);>

Locks the file specified by the file descriptor $fd given the operation $operation.

See L<Sys::IO::Constant|SPVM::Sys::IO::Constant> about constant values given to the operation $operation.

Exceptions:

Exceptions thrown by the L<flock|SPVM::Sys::IO/"flock"> method in the Sys::IO class could be thrown.

=head2 mkdir

C<static method mkdir : void ($path : string, $mode : int);>

Creates the directory given the path $path and the mode $mode.

The permissions of the created directory are ($mode & ~L<umask|/"umask"> & 0777).

In Windows, the mode $mode is ignored.

Exceptions:

Exceptions thrown by the L<mkdir|SPVM::Sys::IO/"mkdir"> method in the Sys::IO class could be thrown.

=head2 umask

C<static method umask : int ($mode : int);>

Sets the umask for the process to the mode $mode and returns the previous value.

Exceptions:

Exceptions thrown by the L<umask|SPVM::Sys::IO/"umask"> method in the Sys::IO class could be thrown.

=head2 unlink

C<static method unlink : void ($pathname : string);>

Deletes a file.

In Windows, this method calls the L<unlink|SPVM::Sys::IO::Windows/"unlink"> method in the Sys::IO::Windows, otherwise calls the L<unlink|SPVM::Sys::IO/"unlink"> method in the Sys::IO class.

Exceptions:

Exceptions thrown by the L<unlink|SPVM::Sys::IO::Windows/"unlink"> method or the L<unlink|SPVM::Sys::IO/"unlink"> method in the Sys::IO class could be thrown.

=head2 rename

C<static method rename : void ($oldpath : string, $newpath : string);>

Raname the file name from the old name $oldpath to the new name $newpath.

In Windows, this method calls the L<rename|SPVM::Sys::IO::Windows/"rename"> method in the Sys::IO::Windows, otherwise calls the L<rename|SPVM::Sys::IO/"rename"> method in the Sys::IO class.

Exceptions:

Exceptions thrown by the L<rename|SPVM::Sys::IO::Windows/"rename"> method or the L<rename|SPVM::Sys::IO/"rename"> method in the Sys::IO class could be thrown.

=head2 rmdir

C<static method rmdir : void ($path : string);>

Deletes the directory given the path $path.

Exceptions:

Exceptions thrown by the L<rmdir|SPVM::Sys::IO/"rmdir"> method in the Sys::IO class could be thrown.

=head2 chdir

C<static method chdir : void ($path : string);>

Changes the working directory to the path $path.

Exceptions:

Exceptions thrown by the L<chdir|SPVM::Sys::IO/"chdir"> method in the Sys::IO class could be thrown.

=head2 chmod

C<static method chmod : void ($mode :int, $path : string);>

Changes the permissions of the file $path to the permission $mode.

Exceptions:

Exceptions thrown by the L<chmod|SPVM::Sys::IO/"chmod"> method in the Sys::IO class could be thrown.

=head2 chown

C<static method chown : void ($owner : int, $group : int, $path : string);>

Changes the owner and the group of the file $path to $owner and $group.

Exceptions:

Exceptions thrown by the L<chown|SPVM::Sys::IO/"chown"> method in the Sys::IO class could be thrown.

=head2 readlink

C<static method readlink : int ($file : string);>

Returns the content of the symbolic link file $file.

In Windows thie method calls the L<readlink|SPVM::Sys::IO::Windows/"readlink"> method in the Sys::IO::Windows, otherwise calls the L<readlink|SPVM::Sys::IO/"readlink"> method in the Sys::IO.

Exceptions:

Exceptions thrown by the L<readlink|SPVM::Sys::IO/"readlink"> method in the Sys::IO or the L<readlink|SPVM::Sys::IO::Windows/"readlink"> method in the Sys::IO::Windows class could be thrown.

=head2 symlink

C<static method symlink : int ($oldpath : string, $newpath : string);>

Creates a path $newpath symbolically linked to the path $oldpath.

In Windows thie method calls the L<symlink|SPVM::Sys::IO::Windows/"symlink"> method in the Sys::IO::Windows, otherwise calls the L<symlink|SPVM::Sys::IO/"symlink"> method in the Sys::IO.

Exceptions:

Exceptions thrown by the L<symlink|SPVM::Sys::IO/"symlink"> method in the Sys::IO or the L<symlink|SPVM::Sys::IO::Windows/"symlink"> method in the Sys::IO::Windows class could be thrown.

=head2 truncate

C<static method truncate : void ($fd : int, $legnth : long);>

Truncates the file referenced by the file descriptor $fd to a size of precisely length bytes $legnth.

Exceptions:

Exceptions thrown by the L<ftruncate|SPVM::Sys::IO/"ftruncate"> method in the Sys::IO class could be thrown.

=head2 opendir

C<static method opendir : void ($dh_ref : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>[], $dir : string);>

Opens the directory stream given the directory $dir.

The opened directory stream is set to $dh_ref at index 0.

Exceptions:

Exceptions thrown by the L<opendir|SPVM::Sys::IO/"opendir"> method in the Sys::IO class could be thrown.

=head2 closedir

C<static method closedir : void ($dstream : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>);>

Closes the directory stream given the directory $dstream.

Exceptions:

Exceptions thrown by the L<closedir|SPVM::Sys::IO/"closedir"> method in the Sys::IO class could be thrown.

=head2 readdir

C<static method readdir : L<Sys::IO::Dirent|SPVM::Sys::IO::Dirent> ($dstream : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>);>

Reads a directory entry from the dirctory stream $dstream.

Exceptions:

Exceptions thrown by the L<readdir|SPVM::Sys::IO/"readdir"> method in the Sys::IO class could be thrown.

=head2 rewinddir

C<static method rewinddir : void ($dstream : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>);>

Resets the position of the directory stream $dstream to the beginning of the directory.

Exceptions:

Exceptions thrown by the L<rewinddir|SPVM::Sys::IO/"rewinddir"> method in the Sys::IO class could be thrown.

=head2 telldir

C<static method telldir : long ($dstream : L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>);>

Returns the current location associated with the directory stream $dstream.

Exceptions:

Exceptions thrown by the L<telldir|SPVM::Sys::IO/"telldir"> method in the Sys::IO class could be thrown.

=head2 popen

C<static method popen : void ($stream_ref : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>[], $open_mode : string, $command : string);>

Opens a file stream that joins a process by creating a pipe given the command $command and the open mode $open_mode.

The opened file stream is set to $stream_ref at index 0.

The open mode $open_mode is replaced to a representation of the L<fopen|https://linux.die.net/man/3/fopen> function before calling the L<fopen|https://linux.die.net/man/3/fopen> function.

  [$open_mode]   [The mode of the fopen function]
  |-             wb
  -|             rb

If the system supports C<FD_CLOEXEC>, this flag is set to the opened file's file descriptor using L</"fcntl">.

Exceptions:

Exceptions thrown by the L<popen|SPVM::Sys::IO/"popen"> method in the Sys::IO or the L<_popen|SPVM::Sys::IO/"_popen"> method in the Sys::IO class could be thrown.

=head2 pclose

C<static method pclose : void ($stream : L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>);>

Closes the file stream $stream created by the L</"popen"> method.

Exceptions:

Exceptions thrown by the L<pclose|SPVM::Sys::IO/"pclose"> method in the Sys::IO or the L<_pclose|SPVM::Sys::IO/"_pclose"> method in the Sys::IO class could be thrown.

=head2 select

C<static method select : int ($readfds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $writefds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $exceptfds : L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>, $timeout : double = 0);>

Calls the L<select|SPVM::Sys::Select/"select"> method in the Sys::Select class and returns its return value.

If $timeout is greter than or equal to 0, it is converted to a L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval> object. Otherwise is converted to undef.

$nfds is set to 1024.

Exceptions:

Exceptions thrown by the L<select|SPVM::Sys::Select/"select"> method in the Sys::Select class method could be thrown.

=head2 ioctl

C<static method ioctl : int ($fd : int, $request : int, $request_arg_ref : object of byte[]|short[]|int[]|long[]|float[]|double[]|object = undef);>

Windows:

Calls the L<ioctlsocket|SPVM::Sys::Ioctl/"ioctlsocket"> method in the L<Sys::Ioctl|SPVM::Sys::Ioctl> class and returns its return value.

OSs other than Windows:

Calls the L<ioctl|SPVM::Sys::Ioctl/"ioctl"> method in the L<Sys::Ioctl|SPVM::Sys::Ioctl> class and returns its return value.

Exceptions:

Exceptions thrown by the L<ioctl|SPVM::Sys::Ioctl/"ioctl"> method or the L<ioctlsocket|SPVM::Sys::Ioctl/"ioctlsocket"> method in the L<Sys::Ioctl|SPVM::Sys::Ioctl> class could be thrown.

=head2 A

C<static method A : double ($file : string);>

Returns script start time minus file access time of the file $file, in days.

This method corresponds to Perl's  L<-A|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

The exceptions thrown by he L</"stat"> method could be thrown.

=head2 C

C<static method C : double ($file : string);>

Returns script start time minus file inode change time of the file $file, in days.

This method corresponds to Perl's  L<-C|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

The exceptions thrown by he L</"stat"> method could be thrown.

=head2 M

C<static method M : double ($file : string);>

Returns script start time minus file modification time of the file $file, in days.

This method corresponds to Perl's  L<-M|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

The exceptions thrown by he L</"stat"> method could be thrown.

=head2 O

C<static method O : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Othersize if the file $file is owned by real uid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-O|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 R

C<static method R : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is readable by real uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-R|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 S

C<static method S : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is a socket, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-S|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 W

C<static method W : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is writable by real uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-W|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 X

C<static method X : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is executable by real uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-X|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 b

C<static method b : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is a block special file, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-b|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 c

C<static method c : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is a character special file, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-c|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 d

C<static method d : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

Otherwise if the file $file is a directory, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-d|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 e

C<static method e : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value. 

This method corresponds to Perl's  L<-e|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 f

C<static method f : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is a plain file, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-f|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 g

C<static method g : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file has setgid bit set, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-g|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 k

C<static method k : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file has sticky bit set, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-k|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 l

C<static method l : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"lstat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is a symbolic link (false if symlinks aren't supported by the file system), returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-l|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 o

C<static method o : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is owned by effective uid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-l|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 p

C<static method p : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is a named pipe (FIFO), or Filehandle is a pipe, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-p|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 r

C<static method r : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is readable by effective uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-r|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 s

C<static method s : long ($file : string);>

If the file $file has nonzero size, returns its size in bytes, otherwise returns 0.

This method corresponds to Perl's  L<-s|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

The exceptions thrown by he L</"stat"> method could be thrown.

=head2 u

C<static method u : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file has setuid bit set, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-u|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 w

C<static method w : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is writable by effective uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-u|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 x

C<static method x : int ($file : string);>

If If the file doesn't exist or can't be examined(These checks are done by the L</"stat"> method), returns 0 and L<errno|SPVM::Errno/"errno"> is set to a positive value.

Otherwise if the file $file is executable by effective uid/gid, returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-x|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

=head2 z

C<static method z : int ($file : string);>

If the file $file has zero size (is empty), returns 1, otherwise returns 0.

This method corresponds to Perl's  L<-z|https://perldoc.perl.org/functions/-X>.

Exceptions:

$file must be defined. Otherwise an exception is thrown.

The exceptions thrown by he L</"stat"> method could be thrown.

=head2 time

C<static method time : long ();>

Returns the current epoch time.

=head2 localtime

C<static method localtime : L<Sys::Time::Tm|SPVM::Sys::Time::Tm> ($epoch : long = -1, $allow_minus = 0);>

Converts the epoch time $epoch to a L<Sys::Time::Tm|SPVM::Sys::Time::Tm> object, and returns it.

The return value is localized for the local time zone.

If $allow_minus is 0 and $epoch is less than 0, $epoch is set to the current epoch time.

=head2 gmtime

C<static method gmtime : L<Sys::Time::Tm|SPVM::Sys::Time::Tm> ($epoch : long = -1, $allow_minus = 0);>

Works just like L</"localtime">, but the returned values are for the UTC time zone.

=head2 utime

C<static method utime : void ($atime : long, $mtime : long, $filename : string);>

Changes the access time and the modification time of the inode specified by the file $filename given the access time $atime and the modification time $mtime.

If $atime < 0 and $mtime < 0, changes the access time and the modification time to the current time..

Exceptions:

Exceptions thrown by the L<utime|SPVM::Sys::Time/"utime"> method in the Sys::Time class could be thrown.

=head2 stat

C<static method stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ($path : string);>

Returns information about a file $path.

Exceptions:

Exceptions thrown by the L<stat|SPVM::Sys::IO::Stat/"stat"> method in the Sys::IO::Stat class could be thrown.

=head2 lstat

C<static method lstat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ($path : string);>

Identical to L</"stat">, except that if path $path is a symbolic link(or directory junction only in Windows), then the link itself is stat-ed, not the file that it refers to.

In Windows, this method calls the L<lstat|SPVM::Sys::IO::Windows/"lstat"> method, otherwise calls the L<lstat|SPVM::Sys::IO::Stat/"lstat"> method.

Exceptions:

Exceptions thrown by the L<lstat|SPVM::Sys::IO::Stat/"lstat"> method in the Sys::IO::Stat class or the L<lstat|SPVM::Sys::IO::Windows/"lstat"> method in the Sys::IO::Windows class could be thrown.

=head2 fstat

C<static method fstat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ($fd : int);>

Identical to L</"stat">, except that the file to be stat-ed is specified by the file descriptor $fd.

Exceptions:

Exceptions thrown by the L<fstat|SPVM::Sys::IO::Stat/"fstat"> method in the Sys::IO::Stat class could be thrown.

=head2 env

C<static method env : string ($name : string);>

Gets an environment variable with the name $name.

=head2 set_env

C<static method set_env : void ($name : string, $value : string);>

Sets an environment variable with the name $name and the value $value.

If $value is undef or "", the environment variable is removed.

Exceptions:

This method calls the following methods, so exceptions thrown by these methods could be thrown.

=over 2

=item * L<_putenv_s|SPVM::Sys::Env/"_putenv_s"> in Sys::Env

=item * L<setenv|SPVM::Sys::Env/"setenv"> in Sys::Env

=item * L<unsetenv|SPVM::Sys::Env/"unsetenv"> in Sys::Env

=back

=head2 osname

C<static method osname : string ()>

Gets the OS name. This method corresponds to Perl's L<$^O|https://perldoc.perl.org/perlvar#$%5EO>.

=over 2

=item * C<linux>

=item * C<darwin>

=item * C<MSWin32>

=item * C<freebsd>

=item * C<openbsd>

=item * C<solaris>

=back

Exceptions:

If the OS name could not be determined, an exception is thrown.

=head2 socket

C<static method socket : void ($sockfd_ref : int*, $domain : int, $type : int, $protocol : int);>

Opens a socket given the domain $domain, the type $type, and the protocal $protocol.

The created socket file descriptor is set to the value referenced by $sockfd_ref.

This method calls the L<socket|SPVM::Sys::Socket/"socket"> method in the Sys::Socket class.

If the system supports C<FD_CLOEXEC>, this flag is set to the value referenced by $sockfd_ref using L</"fcntl">.

Exceptions:

Exceptions thrown by the L<socket|SPVM::Sys::Socket/"socket"> method in the Sys::Socket class could be thrown.

=head2 connect

C<static method connect : void ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>);>

Attempts to connect to a remote socket, just like the C<connect> system call.

This method calls the L<connect|SPVM::Sys::Socket/"connect"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<connect|SPVM::Sys::Socket/"connect"> method in the Sys::Socket class could be thrown.

=head2 bind

C<static method bind : void ($sockfd : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>);>

Binds a network address $addr to the socket $sockfd.

This method calls the L<bind|SPVM::Sys::Socket/"bind"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<bind|SPVM::Sys::Socket/"bind"> method in the Sys::Socket could be thrown.

=head2 listen

C<static method listen : void ($sockfd : int, $backlog : int);>

Does the same thing that the C<listen> system call does.

This method calls the L<listen|SPVM::Sys::Socket/"listen"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<listen|SPVM::Sys::Socket/"listen"> method in the Sys::Socket could be thrown.

=head2 accept

C<static method accept : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ($new_sockfd_ref : int*, $sockfd : int);>

Accepts an incoming socket connect, just as the C<accept> system call does. Returns the packed address.

A new connected socket file descriptor is set to the value referenced by $new_sockfd_ref.

Thie methods calls the L<accept|SPVM::Sys::Socket/"accept"> method in the Sys::Socket class.

The returned packed address is upgraded to a child class of the L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> using L<upgrade|SPVM::Sys::Socket::Sockaddr/"upgrade"> method.

If the system supports C<FD_CLOEXEC>, this flag is set to the value referenced by $new_sockfd_ref using L</"fcntl">.

Exceptions:

Exceptions thrown by the L<accept|SPVM::Sys::Socket/"accept"> method in the Sys::Socket could be thrown.

=head2 recv

C<static method recv : int ($sockfd : int, $buf : mutable string, $len : int, $flags : int, $buf_offset : int = 0);>

Receives a message on a socket.

This method calls the L<recv|SPVM::Sys::Socket/"recv"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<recv|SPVM::Sys::Socket/"recv"> method in the Sys::Socket could be thrown.

=head2 send

C<static method send : int ($sockfd : int, $buf : string, $flags : int, $addr : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> = undef, $len : int = -1, $buf_offset : int = 0)>

Sends a message on a socket.

If $len is less than 0, The length of $buffer is set to $len.

If $addr is undef, This method calls the L<send|SPVM::Sys::Socket/"send"> method in the Sys::Socket class, otherwise calls the L<sendto|SPVM::Sys::Socket/"sendto"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<send|SPVM::Sys::Socket/"send"> method or the L<sendto|SPVM::Sys::Socket/"sendto"> method in the Sys::Socket could be thrown.

=head2 shutdown

C<static method shutdown : void ($sockfd : int, $how : int);>

Shuts down a socket  connection $sockfd in the manner indicated by $how.

This method calls the L<shutdown|SPVM::Sys::Socket/"shutdown"> method in the Sys::Socket class.

Exceptions:

Exceptions thrown by the L<shutdown|SPVM::Sys::Socket/"shutdown"> method in the Sys::Socket could be thrown.

=head2 getpeername

C<static method getpeername : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ($sockfd : int);>

Returns the packed sockaddr address of the other end of the socket connection $sockfd.

This method calls the L<getpeername|SPVM::Sys::Socket/"getpeername"> method in the Sys::Socket class.

The returned packed sockaddr address is upgraded to a child class of the L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> using L<upgrade|SPVM::Sys::Socket::Sockaddr/"upgrade"> method.

Exceptions:

Exceptions thrown by the L<getpeername|SPVM::Sys::Socket/"getpeername"> method in the Sys::Socket could be thrown.

=head2 getsockname

C<static method getsockname : L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> ($sockfd : int)>

Returns the packed sockaddr address of this end of the socket connection $sockfd.
            
Thie method calls the L<getsockname|SPVM::Sys::Socket/"getsockname"> method in the Sys::Socket class.

The returned packed sockaddr address is upgraded to a child class of the L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr> using L<upgrade|SPVM::Sys::Socket::Sockaddr/"upgrade"> method.

Exceptions:

Exceptions thrown by the L<getsockname|SPVM::Sys::Socket/"getsockname"> method in the Sys::Socket could be thrown.

=head2 socketpair

C<static method socketpair : void ($sock_fd1_ref : int*, $sock_fd2_ref : int*, $domain : int, $type : int, $protocol : int);>

Creates an unnamed pair of sockets in the specified domain, of
the specified type. The domain $domain, the type $type, the protocal $protocol are specified the
same as for the syscall of the same name.

The opened reading file descripor is set to the value referenced by $sock_fd1_ref.

The opened writing file descripor is set to the value referenced by $sock_fd2_ref.

This method calls the L<socketpair|SPVM::Sys::Socket/"socketpair"> method in the Sys::Socket.

If available, C<FD_CLOEXEC> is set to the file descriptor of the value referenced by $sock_fd1_ref and the value referenced by $sock_fd2_ref.

Exceptions:

Exceptions thrown by the L<socketpair|SPVM::Sys::Socket/"socketpair"> method in the Sys::Socket could be thrown.

=head2 setsockopt

C<static method setsockopt : void ($sockfd : int, $level : int, $optname : int, $optval : object of string|Int);>

Sets the socket option requested.

This method calls the L<getsockopt|SPVM::Sys::Socket/"getsockopt"> method in the Sys::Socket class.

Exceptions:

$optval must be defined. Otherwise an exception is thrown.

The type of \$optval must be the Int or string type.

Exceptions thrown by the L<getsockopt|SPVM::Sys::Socket/"getsockopt"> method in the Sys::Socket could be thrown.

=head2 getsockopt

C<static method getsockopt : string ($sockfd : int, $level : int, $optname : int, $optlen : int = -1);>

If $optlen is less than 0, it is set to 4.

This method calls the L<getsockopt|SPVM::Sys::Socket/"getsockopt"> method in the Sys::Socket class.

Examples:

Getting an int value:

  my $reuseaddr_packed = Sys->getsockopt($socket, SOCKET->SOL_SOCKET, SOCKET->SO_REUSEADDR);
  my $reuseaddr_ref = [0];
  Fn->memcpy($reuseaddr_ref, 0, $reuseaddr_packed, 0, 4);
  my $reuseaddr = $reuseaddr_ref->[0];

Exceptions:

Exceptions thrown by the L<getsockopt|SPVM::Sys::Socket/"getsockopt"> method in the Sys::Socket could be thrown.

=head2 signal

C<static method signal : void ($signum : int, $handler_name : string);>

Sets a signal handler with its name $handler_name for the given signal number $signum.

If $handler_name is "DEFAULT", the signal handler is L<"SIG_DFL"|SPVM::Sys::Signal/"SIG_DFL">.

If $handler_name is "IGNORE", the signal handler is L<"SIG_IGN"|SPVM::Sys::Signal/"SIG_IGN">.

See the L<signal|SPVM::Sys::Signal/"signal"> method in the Sys::Signal class in detail.

Exceptions:

If $handler_name is not available, an exception is thrown.

The exceptions thrown by the L<signal|SPVM::Sys::Signal/"signal"> method in the Sys::Signal class could be thrown.

=head2 kill

C<static method kill : void ($sig : int, $pid : int);>

Send a signal $sig to the process whose process ID is $pid.

See the L<kill|SPVM::Sys::Signal/"kill"> method in the Sys::Signal class in detail.

In Windows, see the L<raise|SPVM::Sys::Signal/"raise"> method in the Sys::Signal class in detail.

Exceptions:

The exceptions thrown by the L<alarm|SPVM::Sys::Signal/"alarm"> method in the Sys::Signal class could be thrown.

The exceptions thrown by the L<raise|SPVM::Sys::Signal/"raise"> method in the Sys::Signal class could be thrown.

$pid must be equal to Sys->process_id in Windows. Otherwise an exception is thrown.

=head2 alarm

C<static method alarm : int ($seconds : int);>

Sets a alarm signal sent after seconds $seconds.

See L<alarm|SPVM::Sys::Signal/"alarm"> method in the Sys::Signal class in detail.

Exceptions:

The exceptions thrown by the L<alarm|SPVM::Sys::Signal/"alarm"> method in the Sys::Signal class could be thrown.

=head2 fork

C<static method fork : int ();>

Forks the process by calling the L<fork|SPVM::Sys::Process/"fork"> method in the Sys::Process method.

It returns the child process ID to the parent process, or returns 0 to the child process.

Exceptions:

Exceptions thrown by the L<fork|SPVM::Sys::Process/"fork"> method in the Sys::Process method could be thrown.

=head2 getpriority

C<static method getpriority : int ($which : int, $who : int);>

Return the scheduling priority of the process, process group, or user, as indicated by $which and $who is obtained.

Exceptions:

Exceptions thrown by the L<getpriority|SPVM::Sys::Process/"getpriority"> method in the Sys::Process method could be thrown.

=head2 setpriority

C<static method setpriority : void ($which : int, $who : int, $prio : int)>

Sets the scheduling priority of the process, process group, or user, as indicated by $which and $who is obtained.

Exceptions:

Exceptions thrown by the L<setpriority|SPVM::Sys::Process/"setpriority"> method in the Sys::Process method could be thrown.

=head2 sleep

C<static method sleep : int ($seconds : int);>

Sleeps for the seconds $seconds.

=head2 wait

C<static method wait : int ($wstatus_ref : int*);>

Waits for state changes in a child of the calling process, and returns a process ID whose state is changed.

The status about the child whose state has changed is set to $wstatus_ref.

The following method in the Sys::Process class checks the value of $wstatus_ref.

=over 2

=item * L<WIFEXITED|SPVM::Sys::Process/"WIFEXITED">

=item * L<WEXITSTATUS|SPVM::Sys::Process/"WEXITSTATUS">

=item * L<WIFSIGNALED|SPVM::Sys::Process/"WIFSIGNALED">

=item * L<WTERMSIG|SPVM::Sys::Process/"WTERMSIG">

=item * L<WCOREDUMP|SPVM::Sys::Process/"WCOREDUMP">

=item * L<WIFEXITED|SPVM::Sys::Process/"WIFEXITED">

=item * L<WIFSTOPPED|SPVM::Sys::Process/"WIFSTOPPED">

=item * L<WSTOPSIG|SPVM::Sys::Process/"WSTOPSIG">

=item * L<WIFCONTINUED|SPVM::Sys::Process/"WIFCONTINUED">

=back

Exceptions:

Exceptions thrown by the L<wait|SPVM::Sys::Process/"wait"> method in the Sys::Process method could be thrown.

=head2 waitpid

C<static method waitpid : int ($pid : in, $options : int, $wstatus_ref : int*);>

Same as the L</"wait"> method, but can give the process ID $pid and the options $options.

See L<Sys::Process::Constant|SPVM::Sys::Process::Constant> about constant values given to $options.

Exceptions:

Exceptions thrown by the L<waitpid|SPVM::Sys::Process/"waitpid"> method in the Sys::Process method could be thrown.

=head2 system

C<static method system : int ($command : string);>

Executes a command specified in command using shell and return the L</"wait"> status.

=head2 exit

C<static method exit : void ($status : int);>

Terminates the calling process immediately with the status $status.

=head2 pipe

C<static method pipe : void ($read_fd_ref : int*, $write_fd_ref : int*);>

Opens a pair of pipes.

If the system supports C<FD_CLOEXEC>, this flag is set to the value referenced by $read_fd_ref and the value referenced by $write_fd_ref using L</"fcntl">.

=head2 getpgrp

C<static method getpgrp : int ($pid : int);>

Gets the process group number given the process ID $pid of the running this program.

=head2 setpgrp

C<static method setpgrp : void ($pid : int, $pgid : int);>

Sets the process group number $pgid given the process ID $pid of the running this program.

=head2 process_id

C<static method process_id : int ();>

Gets the process number of the running this program.

=head2 getppid

C<static method getppid : int ();>

Returns the process ID of the parent of the calling process.

=head2 exec

C<static method exec : void ($program : string, $args : string[] = undef);>

Executes the program $program with the arguments $args without using shell and never returns.

Examples:

  Sys->exec("/bin/echo", ["-n", "Hello"]);

=head2 real_user_id

C<static method real_user_id : int ();>

Gets the real user ID of this process.

=head2 effective_user_id

C<static method effective_user_id : int ();>

Gets the effective user ID of this process.

=head2 real_group_id

C<static method real_group_id : int ();>

Gets the real group ID of this process.

=head2 effective_group_id

C<static method effective_group_id : int ();>

Gets the effective group ID of this process.

=head2 set_real_user_id

C<static method set_real_user_id : int ($uid : int);>

Sets the real user ID of this process.

=head2 set_effective_user_id

C<static method set_effective_user_id : int ($euid : int);>

Sets the effective user ID of this process.

=head2 set_real_group_id

C<static method set_real_group_id : int ($gid : int);>

Sets the real group ID of this process.

=head2 set_effective_group_id

C<static method set_effective_group_id : int ($egid : int);>

Sets the effective group ID of this process.

=head2 setpwent

C<static method setpwent : void ();>

Rewinds to the beginning of the password database.

=head2 endpwent

C<static method endpwent : void ();>

Closes the password database after all processing has been performed.

=head2 getpwent

C<static method getpwent : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ();>

Gets a next password entry.

=head2 setgrent

C<static method setgrent : void ();>

Rewinds to the beginning of the group database.

=head2 endgrent

C<static method endgrent : void ();>

Closes the group database after all processing has been performed.

=head2 getgrent

C<static method getgrent : L<Sys::User::Group|SPVM::Sys::User::Group> ();>

Gets a next group entry.

=head2 getgroups

C<static method getgroups : int[] ();>

Returns the supplementary group IDs of the calling process.

=head2 setgroups

C<static method setgroups : void ($groups : int[]);>

Sets the supplementary group IDs for the calling process.

=head2 getpwuid

C<static method getpwuid : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ($id : int);>

Searches a password entry given The user ID $id. If found, returns the password entry, otherwise return undef.

=head2 getpwnam

C<static method getpwnam : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ($name : string);>

Searches a password entry given The user name $name. If found, returns the password entry, otherwise return undef.

=head2 getgrgid

C<static method getgrgid : L<Sys::User::Group|SPVM::Sys::User::Group> ($id : int);>

Searches a group entry given The group ID $id. If found, returns the group entry, otherwise return undef.

=head2 getgrnam

C<static method getgrnam : L<Sys::User::Group|SPVM::Sys::User::Group> ($name : string);>

Searches a group entry given The group name $name. If found, returns the group entry, otherwise return undef.

=head1 Modules

=over 2

=item * L<Sys::Env|SPVM::Sys::Env>

=item * L<Sys::IO|SPVM::Sys::IO>

=item * L<Sys::IO::Constant|SPVM::Sys::IO::Constant>

=item * L<Sys::Ioctl|SPVM::Sys::Ioctl>

=item * L<Sys::Ioctl::Constant|SPVM::Sys::Ioctl::Constant>

=item * L<Sys::IO::Dirent|SPVM::Sys::IO::Dirent>

=item * L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>

=item * L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>

=item * L<Sys::IO::Flock|SPVM::Sys::IO::Flock>

=item * L<Sys::IO::Stat|SPVM::Sys::IO::Stat>

=item * L<Sys::IO::Windows|SPVM::Sys::IO::Windows>

=item * L<Sys::OS|SPVM::Sys::OS>

=item * L<Sys::Poll|SPVM::Sys::Poll>

=item * L<Sys::Poll::Constant|SPVM::Sys::Poll::Constant>

=item * L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray>

=item * L<Sys::Process|SPVM::Sys::Process>

=item * L<Sys::Process::Constant|SPVM::Sys::Process::Constant>

=item * L<Sys::Select|SPVM::Sys::Select>

=item * L<Sys::Select::Constant|SPVM::Sys::Select::Constant>

=item * L<Sys::Select::Fd_set|SPVM::Sys::Select::Fd_set>

=item * L<Sys::Signal|SPVM::Sys::Signal>

=item * L<Sys::Signal::Constant|SPVM::Sys::Signal::Constant>

=item * L<Sys::Signal::Handler|SPVM::Sys::Signal::Handler>

=item * L<Sys::Socket|SPVM::Sys::Socket>

=item * L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>

=item * L<Sys::Socket::AddrinfoLinkedList|SPVM::Sys::Socket::AddrinfoLinkedList>

=item * L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant>

=item * L<Sys::Socket::Errno|SPVM::Sys::Socket::Errno>

=item * L<Sys::Socket::Error|SPVM::Sys::Socket::Error>

=item * L<Sys::Socket::Error::InetInvalidNetworkAddress|SPVM::Sys::Socket::Error::InetInvalidNetworkAddress>

=item * L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr>

=item * L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>

=item * L<Sys::Socket::In_addr_base|SPVM::Sys::Socket::In_addr_base>

=item * L<Sys::Socket::Ip_mreq|SPVM::Sys::Socket::Ip_mreq>

=item * L<Sys::Socket::Ip_mreq_source|SPVM::Sys::Socket::Ip_mreq_source>

=item * L<Sys::Socket::Ipv6_mreq|SPVM::Sys::Socket::Ipv6_mreq>

=item * L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=item * L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In>

=item * L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6>

=item * L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage>

=item * L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un>

=item * L<Sys::Socket::Util|SPVM::Sys::Socket::Util>

=item * L<Sys::Time|SPVM::Sys::Time>

=item * L<Sys::Time::Constant|SPVM::Sys::Time::Constant>

=item * L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>

=item * L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>

=item * L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>

=item * L<Sys::Time::Timezone|SPVM::Sys::Time::Timezone>

=item * L<Sys::Time::Tm|SPVM::Sys::Time::Tm>

=item * L<Sys::Time::Tms|SPVM::Sys::Time::Tms>

=item * L<Sys::Time::Util|SPVM::Sys::Time::Util>

=item * L<Sys::Time::Utimbuf|SPVM::Sys::Time::Utimbuf>

=item * L<Sys::User|SPVM::Sys::User>

=item * L<Sys::User::Group|SPVM::Sys::User::Group>

=item * L<Sys::User::Passwd|SPVM::Sys::User::Passwd>

=back

=head1 See Also

=over 2

=item * L<IO|SPVM::IO> - File IO, Sockets

=item * L<File::Spec|SPVM::File::Spec>

=item * L<File::Temp|SPVM::File::Temp>

=item * L<File::Copy|SPVM::File::Copy>

=item * L<File::Find|SPVM::File::Find>

=item * L<File::Glob|SPVM::File::Glob>

=item * L<Cwd|SPVM::Cwd>

=item * L<Time::HiRes|SPVM::Time::HiRes>

=item * L<Go|SPVM::Go>

=back

=head1 Repository

L<SPVM::Sys - Github|https://github.com/yuki-kimoto/SPVM-Sys>

=head1 Author

Yuki Kimoto(L<https://github.com/yuki-kimoto>)

=head1 Contributors

Gabor Szabo(L<https://github.com/szabgab>)

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
