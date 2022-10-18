package SPVM::Sys::FileTest;

1;

=head1 Name

SPVM::Sys::FileTest - File Tests

=head1 Usage
  
  use Sys::FileTest;
  
  my $file = "foo.txt";
  if (Sys::FileTest->e($file))
    
  }
  
  if (Sys::FileTest->f($file))
    
  }
  
  if (Sys::FileTest->d($file))
    
  }

=head1 Description

C<Sys::FileTest> is the class for file tests.

=head1 Class Methods

=head2 R

  static method R : int ($file : string)

File is readable by real uid/gid.

=head2 W

  static method W : int ($file : string)

File is writable by real uid/gid.

=head2 X

  static method X : int ($file : string)

File is executable by real uid/gid.

=head2 r

  static method r : int ($file : string)

File is readable by effective uid/gid.

=head2 w

  static method w : int ($file : string)

File is writable by effective uid/gid.

=head2 x

  static method x : int ($file : string)

File is executable by effective uid/gid.

=head2 e

  static method e : int ($file : string)

File exists.

=head2 s

  static method s : long ($file : string)

File has nonzero size (returns size in bytes).

=head2 M

  static method M : double ($file : string, $base_time : long)

Script start time(base time) minus file modification time, in days.

=head2 C

  static method C : double ($file : string, $base_time : long)

Script start time(base time) minus file inode change time, in days.

=head2 A

  static method A : double ($file : string, $base_time : long)

Script start time(base time) minus file access time, in days.

=head2 O

  static method O : int ($file : string)

File is owned by real uid.

=head2 o

  static method o : int ($file : string)

File is owned by effective uid.

=head2 z

  static method z : int ($file : string)

File has zero size (is empty).

=head2 S

  static method S : int ($file : string)

File is a socket.

=head2 c

  static method c : int ($file : string)

File is a character special file.
 
=head2 b

  static method b : int ($file : string)

File is a block special file.

=head2 f

  static method f : int ($file : string)

File is a plain file.

=head2 d

  static method d : int ($file : string)

File is a directory.

=head2 p

  static method p : int ($file : string)

File is a named pipe (FIFO), or Filehandle is a pipe.
 
=head2 u

  static method u : int ($file : string)

File has setuid bit set.

=head2 g

  static method g : int ($file : string)

File has setgid bit set.

=head2 k

  static method k : int ($file : string)

File has sticky bit set.

=head2 l

  static method l : int ($file : string)

File is a symbolic link (false if symlinks aren't supported by the file system).
                    
