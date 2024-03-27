package SPVM::Sys::OS;

1;

=head1 Name

SPVM::Sys::OS - OS Information

=head1 Description

The SPVM::Sys::OS class in L<SPVM> has methods to get OS information.

=head1 Usage

  use Sys::OS;
  
  my $is_windows = Sys::OS->defined("_WIN32");

  my $is_windows = Sys::OS->is_windows;

=head1 Class Methods

=head2 defined

C<static method defined : int ($macro_name : string, $value_ref : object of int[]|long[]|double[] = undef);>

Checks if the macro $macro_name is defined on the system. If the macro is defined, returns 1, otherwise returns 0.

If $value_ref is given, the macro value is set to the first element of $value_ref.

The following macro names are supported.

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

Exceptions:

$value_ref must be the int[], long[], or double[] type. Otherwise an exception is thrown.

If the macro name is not supported, an exception is thrown.

=head2 is_windows

C<static method is_windows : int ();>

If the OS is Windows(C<_WIN32> is defined), returns 1, otherwise returns 0.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

