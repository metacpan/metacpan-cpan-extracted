package SPVM::Sys;

our $VERSION = '0.25';

1;

=head1 Name

SPVM::Sys - System Calls for File IO, User, Process, Signal, Socket

=head1 Caution

The C<Sys> module and the system modules will be highly changed without warnings.

L<SPVM> itself is yet experimental release.

=head1 Description

C<Sys> is the class for system calls such as file IO, user manipulation, process, socket, time,

=head1 Modules

The list of the modules that provide system calls.

=head2 Sys::IO

L<Sys::IO|SPVM::Sys::IO> - File I/O

=head2 Sys::Ioctl

L<Sys::Ioctl|SPVM::Sys::Ioctl> - The C<ioctl> function

=head2 Sys::Socket

L<Sys::Socket|SPVM::Sys::Socket> - Socket

=head2 Sys::Select

L<Sys::Select|SPVM::Sys::Select> - The C<select> function

=head2 Sys::Poll

L<Sys::Poll|SPVM::Sys::Poll> - The C<poll> function.

=head2 Sys::Process

L<Sys::Process|SPVM::Sys::Process> - Process Manipulation

=head2 Sys::Signal

L<Sys::Signal|SPVM::Sys::Signal> - Signal

=head2 Sys::Time

L<Sys::Time|SPVM::Sys::Time> - Time Manipulation

=head2 Sys::User

L<Sys::User|SPVM::Sys::User> - User Manipulation

=head2 Sys::FiteTest

L<Sys::FiteTest|SPVM::Sys::FiteTest> - File Tests

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

