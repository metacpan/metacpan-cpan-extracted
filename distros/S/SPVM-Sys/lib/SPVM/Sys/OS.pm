package SPVM::Sys::OS;

1;

=head1 Name

SPVM::Sys::OS - System Calls for OS

=head1 Description

C<SPVM::Sys::OS> is the C<Sys::OS> class in L<SPVM> language. It provides system calls for OS.

=head1 Usage

  use Sys::OS;
  
  my $is_windows = Sys::OS->defined("_WIN32");

=head1 Class Methods

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

=head2 is_windows

  static method is_windows : int ();

If the OS is C<Windows>, returns C<1>, otherwise returns C<0>.

=head1 Modules

All modules that is included in this distribution.

=over 2

=item * L<Sys::OS|SPVM::Sys::OS>

=item * L<Sys::OS::FileTest|SPVM::Sys::OS::FileTest>

=item * L<Sys::OS::IO|SPVM::Sys::OS::IO>

=item * L<Sys::OS::IO::Constant|SPVM::Sys::OS::IO::Constant>

=item * L<Sys::OS::Ioctl|SPVM::Sys::OS::Ioctl>

=item * L<Sys::OS::Ioctl::Constant|SPVM::Sys::OS::Ioctl::Constant>

=item * L<Sys::OS::IO::Dirent|SPVM::Sys::OS::IO::Dirent>

=item * L<Sys::OS::IO::DirStream|SPVM::Sys::OS::IO::DirStream>

=item * L<Sys::OS::IO::FileStream|SPVM::Sys::OS::IO::FileStream>

=item * L<Sys::OS::IO::Flock|SPVM::Sys::OS::IO::Flock>

=item * L<Sys::OS::IO::Stat|SPVM::Sys::OS::IO::Stat>

=item * L<Sys::OS::IO::Utimbuf|SPVM::Sys::OS::IO::Utimbuf>

=item * L<Sys::OS::Poll|SPVM::Sys::OS::Poll>

=item * L<Sys::OS::Poll::Constant|SPVM::Sys::OS::Poll::Constant>

=item * L<Sys::OS::Poll::PollfdArray|SPVM::Sys::OS::Poll::PollfdArray>

=item * L<Sys::OS::Process|SPVM::Sys::OS::Process>

=item * L<Sys::OS::Process::Constant|SPVM::Sys::OS::Process::Constant>

=item * L<Sys::OS::Select|SPVM::Sys::OS::Select>

=item * L<Sys::OS::Select::Constant|SPVM::Sys::OS::Select::Constant>

=item * L<Sys::OS::Select::Fd_set|SPVM::Sys::OS::Select::Fd_set>

=item * L<Sys::OS::Signal|SPVM::Sys::OS::Signal>

=item * L<Sys::OS::Signal::Constant|SPVM::Sys::OS::Signal::Constant>

=item * L<Sys::OS::Signal::Handler|SPVM::Sys::OS::Signal::Handler>

=item * L<Sys::OS::Signal::Handler::Default|SPVM::Sys::OS::Signal::Handler::Default>

=item * L<Sys::OS::Signal::Handler::Ignore|SPVM::Sys::OS::Signal::Handler::Ignore>

=item * L<Sys::OS::Signal::Handler::Monitor|SPVM::Sys::OS::Signal::Handler::Monitor>

=item * L<Sys::OS::Signal::Handler::Unknown|SPVM::Sys::OS::Signal::Handler::Unknown>

=item * L<Sys::OS::Socket|SPVM::Sys::OS::Socket>

=item * L<Sys::OS::Socket::Addrinfo|SPVM::Sys::OS::Socket::Addrinfo>

=item * L<Sys::OS::Socket::AddrinfoLinkedList|SPVM::Sys::OS::Socket::AddrinfoLinkedList>

=item * L<Sys::OS::Socket::Constant|SPVM::Sys::OS::Socket::Constant>

=item * L<Sys::OS::Socket::Error|SPVM::Sys::OS::Socket::Error>

=item * L<Sys::OS::Socket::Error::InetInvalidNetworkAddress|SPVM::Sys::OS::Socket::Error::InetInvalidNetworkAddress>

=item * L<Sys::OS::Socket::In6_addr|SPVM::Sys::OS::Socket::In6_addr>

=item * L<Sys::OS::Socket::In_addr|SPVM::Sys::OS::Socket::In_addr>

=item * L<Sys::OS::Socket::Ip_mreq|SPVM::Sys::OS::Socket::Ip_mreq>

=item * L<Sys::OS::Socket::Ip_mreq_source|SPVM::Sys::OS::Socket::Ip_mreq_source>

=item * L<Sys::OS::Socket::Ipv6_mreq|SPVM::Sys::OS::Socket::Ipv6_mreq>

=item * L<Sys::OS::Socket::Sockaddr|SPVM::Sys::OS::Socket::Sockaddr>

=item * L<Sys::OS::Socket::Sockaddr::In|SPVM::Sys::OS::Socket::Sockaddr::In>

=item * L<Sys::OS::Socket::Sockaddr::In6|SPVM::Sys::OS::Socket::Sockaddr::In6>

=item * L<Sys::OS::Socket::Sockaddr::Interface|SPVM::Sys::OS::Socket::Sockaddr::Interface>

=item * L<Sys::OS::Socket::Sockaddr::Storage|SPVM::Sys::OS::Socket::Sockaddr::Storage>

=item * L<Sys::OS::Socket::Sockaddr::Un|SPVM::Sys::OS::Socket::Sockaddr::Un>

=item * L<Sys::OS::Time|SPVM::Sys::OS::Time>

=item * L<Sys::OS::Time::Constant|SPVM::Sys::OS::Time::Constant>

=item * L<Sys::OS::Time::Itimerval|SPVM::Sys::OS::Time::Itimerval>

=item * L<Sys::OS::Time::Timespec|SPVM::Sys::OS::Time::Timespec>

=item * L<Sys::OS::Time::Timeval|SPVM::Sys::OS::Time::Timeval>

=item * L<Sys::OS::Time::Timezone|SPVM::Sys::OS::Time::Timezone>

=item * L<Sys::OS::Time::Tms|SPVM::Sys::OS::Time::Tms>

=item * L<Sys::OS::User|SPVM::Sys::OS::User>

=item * L<Sys::OS::User::Group|SPVM::Sys::OS::User::Group>

=item * L<Sys::OS::User::Passwd|SPVM::Sys::OS::User::Passwd>

=back

=head1 Author

Yuki Kimoto(L<https://github.com/yuki-kimoto>)

=head1 Contributors

Gabor Szabo(L<https://github.com/szabgab>)

=head1 Repository

L<SPVM::Sys::OS - Github|https://github.com/yuki-kimoto/SPVM-Sys::OS>
