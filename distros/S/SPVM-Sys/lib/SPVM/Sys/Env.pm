package SPVM::Sys::Env;

1;

=head1 Name

SPVM::Sys::Env - Environemnt Variables

=head1 Description

The C<Sys::Env> class in L<SPVM> has methods to manipulate environemnt variables.

=head1 Usage

  use Sys::Env;
  
  my $path = Sys::Env->getenv("PATH");
  
  Sys::Env->setenv("PATH", "/foo/bar");

=head1 Class Methods

=head2 getenv

C<static method getenv : string ($name : string);>

Calls the L<getenv|https://linux.die.net/man/3/getenv> function and copy its return value and returns it.

Exceptions:

$name must be defined. Otherwise an exception is thrown.

=head2 setenv

C<static method setenv : int ($name : string, $value : string, $overwrite : int);>

Calls the L<setenv|https://linux.die.net/man/3/setenv> function and returns its return value.

Exceptions:

$name must be defined. Otherwise an exception is thrown.

$value must be defined. Otherwise an exception is thrown.

If setenv failed, an exception is thrown and C<eval_error_id> is set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In Windows the following exception is thrown. setenv is not supported in this system(defined(_WIN32)).

=head2 unsetenv

C<static method unsetenv : int ($name : string);>

Calls the L<unsetenv|https://linux.die.net/man/3/unsetenv> function and returns its return value.

Exceptions:

$name must be defined. Otherwise an exception is thrown.

If unsetenv failed, an exception is thrown and C<eval_error_id> is set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In Windows the following exception is thrown. unsetenv is not supported in this system(defined(_WIN32)).

=head2 _putenv_s

C<static method _putenv_s : int ($name : string, $value : string);>

Calls the L<_putenv_s|https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/putenv-s-wputenv-s?view=msvc-170> function and returns its return value.

Exceptions:

$name must be defined. Otherwise an exception is thrown.

$value must be defined. Otherwise an exception is thrown.

If _putenv_s failed, an exception is thrown and C<eval_error_id> is set to the basic type ID of the L<Error::System|SPVM::Error::System>.

In OSs ohter than Windows the following exception is thrown. _putenv_s is not supported in this system(!defined(_WIN32)).

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

