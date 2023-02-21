package SPVM::Sys;

our $VERSION = '0.42';

1;

=head1 Name

SPVM::Sys - System Calls for File IO, User, Process, Signal, Socket

=head1 Description

C<SPVM::Sys> is the C<Sys> class in L<SPVM> language. It provides system calls such as file IO, user manipulation, process, socket, time,

This distribution contains many modules for system calls such as L<Sys::IO|SPVM::Sys::IO>. See L</"Modules">.

=head1 Usage

  use Sys;
  
  my $path = Sys->getenv("PATH");
  
  my $is_windows = Sys->defined("_WIN32");

=head1 Class Methods

=head2 getenv

  static method getenv : string ($name : string);

The getenv() function searches the environment list to find the environment variable name, and returns a pointer to the corresponding value string.

See the detail of the L<getenv|https://linux.die.net/man/3/getenv> function in the case of Linux.

=head2 setenv

  static method setenv : int ($name : string, $value : string, $overwrite : int);

The setenv() function adds the variable name to the environment with the value value, if name does not already exist. If name does exist in the environment, then its value is changed to value if overwrite is nonzero; if overwrite is zero, then the value of name is not changed. This function makes copies of the strings pointed to by name and value (by contrast with putenv(3)).

See the detail of the L<setenv|https://linux.die.net/man/3/setenv> function in the case of Linux.

=head2 unsetenv

  static method unsetenv : int ($name : string);

The unsetenv() function deletes the variable name from the environment. If name does not exist in the environment, then the function succeeds, and the environment is unchanged.

See the detail of the L<unsetenv|https://linux.die.net/man/3/unsetenv> function in the case of Linux.

=head2 defined

  static method defined : int ($macro_name : string, $value = undef : object of Int|Long|Double);

Checks if the macro in C<C langauge> is defined. If the macro is defined, returns C<1>. Otherwise returns C<0>.

If C<$value> is specifed and C<$macro_name> is defined, the macro value converted to the given type is set to C<$value>.

Supports the following macro names.

=over 2

=item * __GNUC__

=item * __clang__

=item * __BORLANDC__

=item * __INTEL_COMPILER

=item * __unix

=item * __unix__

=item * __linux

=item * __linux__

=item * __FreeBSD__

=item * __NetBSD__

=item * __OpenBSD__

=item * _WIN32

=item * WIN32

=item * _WIN64

=item * _WINDOWS

=item * _CONSOLE

=item * WINVER

=item * _WIN32_WINDOWS

=item * _WIN32_WINNT

=item * WINCEOSVER

=item * __CYGWIN__

=item * __CYGWIN32__

=item * __MINGW32__

=item * __MINGW64__

=item * __APPLE__

=item * __MACH__

=item * __sun

=item * __solaris

=back

=head2 get_osname

  static method get_osname : string ()

Gets the OS name(Perl's L<$^O|https://perldoc.perl.org/perlvar#$%5EO> ). The list of the OS names are described at L<PLATFORMS - perlport|https://perldoc.perl.org/perlport#PLATFORMS>.

The C<get_osname> in the C<Sys> class supports the following os names.

=over 2

=item * linux

=item * darwin

=item * MSWin32

=item * freebsd

=item * openbsd

=item * solaris

=back

=head1 Modules

All modules that is included in this distribution.

=over 2

=item * L<Sys|SPVM::Sys>

=item * L<Sys::FileTest|SPVM::Sys::FileTest>

=item * L<Sys::IO|SPVM::Sys::IO>

=item * L<Sys::IO::Constant|SPVM::Sys::IO::Constant>

=item * L<Sys::Ioctl|SPVM::Sys::Ioctl>

=item * L<Sys::Ioctl::Constant|SPVM::Sys::Ioctl::Constant>

=item * L<Sys::IO::Dirent|SPVM::Sys::IO::Dirent>

=item * L<Sys::IO::DirStream|SPVM::Sys::IO::DirStream>

=item * L<Sys::IO::FileStream|SPVM::Sys::IO::FileStream>

=item * L<Sys::IO::Flock|SPVM::Sys::IO::Flock>

=item * L<Sys::IO::Stat|SPVM::Sys::IO::Stat>

=item * L<Sys::IO::Utimbuf|SPVM::Sys::IO::Utimbuf>

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

=item * L<Sys::Signal::Handler::Default|SPVM::Sys::Signal::Handler::Default>

=item * L<Sys::Signal::Handler::Ignore|SPVM::Sys::Signal::Handler::Ignore>

=item * L<Sys::Signal::Handler::Monitor|SPVM::Sys::Signal::Handler::Monitor>

=item * L<Sys::Signal::Handler::Unknown|SPVM::Sys::Signal::Handler::Unknown>

=item * L<Sys::Socket|SPVM::Sys::Socket>

=item * L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>

=item * L<Sys::Socket::AddrinfoLinkedList|SPVM::Sys::Socket::AddrinfoLinkedList>

=item * L<Sys::Socket::Constant|SPVM::Sys::Socket::Constant>

=item * L<Sys::Socket::Error|SPVM::Sys::Socket::Error>

=item * L<Sys::Socket::Error::InetInvalidNetworkAddress|SPVM::Sys::Socket::Error::InetInvalidNetworkAddress>

=item * L<Sys::Socket::In6_addr|SPVM::Sys::Socket::In6_addr>

=item * L<Sys::Socket::In_addr|SPVM::Sys::Socket::In_addr>

=item * L<Sys::Socket::Ip_mreq|SPVM::Sys::Socket::Ip_mreq>

=item * L<Sys::Socket::Ip_mreq_source|SPVM::Sys::Socket::Ip_mreq_source>

=item * L<Sys::Socket::Ipv6_mreq|SPVM::Sys::Socket::Ipv6_mreq>

=item * L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>

=item * L<Sys::Socket::Sockaddr::In|SPVM::Sys::Socket::Sockaddr::In>

=item * L<Sys::Socket::Sockaddr::In6|SPVM::Sys::Socket::Sockaddr::In6>

=item * L<Sys::Socket::Sockaddr::Interface|SPVM::Sys::Socket::Sockaddr::Interface>

=item * L<Sys::Socket::Sockaddr::Storage|SPVM::Sys::Socket::Sockaddr::Storage>

=item * L<Sys::Socket::Sockaddr::Un|SPVM::Sys::Socket::Sockaddr::Un>

=item * L<Sys::Time|SPVM::Sys::Time>

=item * L<Sys::Time::Constant|SPVM::Sys::Time::Constant>

=item * L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>

=item * L<Sys::Time::Timespec|SPVM::Sys::Time::Timespec>

=item * L<Sys::Time::Timeval|SPVM::Sys::Time::Timeval>

=item * L<Sys::Time::Timezone|SPVM::Sys::Time::Timezone>

=item * L<Sys::Time::Tms|SPVM::Sys::Time::Tms>

=item * L<Sys::User|SPVM::Sys::User>

=item * L<Sys::User::Group|SPVM::Sys::User::Group>

=item * L<Sys::User::Passwd|SPVM::Sys::User::Passwd>

=back

=head1 Author

Yuki Kimoto(L<https://github.com/yuki-kimoto>)

=head1 Contributors

Gabor Szabo(L<https://github.com/szabgab>)

=head1 Repository

L<SPVM::Sys - Github|https://github.com/yuki-kimoto/SPVM-Sys>

=head1 Copyright & License

Copyright Yuki Kimoto 2022-2022, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

