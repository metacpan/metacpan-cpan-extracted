package SPVM::Sys;

our $VERSION = '0.10';

1;

=head1 Name

SPVM::Sys - System Calls such as File IO, User, Process, Socket,

=head1 Caution

The C<Sys> module and the system modules will be highly changed without warnings.

L<SPVM> itself is yet experimental release.

=head1 Description

C<Sys> is the class for system calls such as file IO, user manipulation, process, socket, time,

=head1 System Modules

=over 2

=item * L<Sys::IO|SPVM::Sys::IO>

=item * L<Sys::Socket|SPVM::Sys::Socket>

=item * L<Sys::Process|SPVM::Sys::Process>

=item * L<Sys::Time|SPVM::Sys::Time>

=item * L<Sys::User|SPVM::Sys::User>

=item * L<Sys::FiteTest|SPVM::Sys::FiteTest>

=back

=head1 Class Methods

=head2 is_D_WIN32

  static method is_D_WIN32 : int ()

If C<_WIN32> in C<C language> is defined, return C<1>. Otherwize return C<0>.

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

