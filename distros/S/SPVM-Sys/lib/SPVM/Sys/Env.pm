package SPVM::Sys::Env;

1;

=head1 Name

SPVM::Sys::Env - Environemnt Variable

=head1 Description

C<SPVM::Sys::Env> is the C<Sys::Env> class in L<SPVM> language. It provides system calls for environemnt variables.

=head1 Usage

  use Sys::Env;
  
  my $path = Sys::Env->getenv("PATH");

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
