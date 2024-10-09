package SPVM::Sys::User;

1;

=head1 Name

SPVM::Sys::User - User/Group System Calls

=head1 Description

Sys::User class in L<SPVM> has methods to call user/group system calls.

=head1 Usage
  
  use Sys::User;
  
  my $effective_user_id = Sys::User->geteuid;

=head1 Class Methods

=head2 getuid

C<static method getuid : int ();>

Calls the L<getuid|https://linux.die.net/man/2/getuid> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. getuid is not supported in this system(defined(_WIN32)).

=head2 geteuid

C<static method geteuid : int ();>

Calls the L<geteuid|https://linux.die.net/man/2/geteuid> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. geteuid is not supported in this system(defined(_WIN32)).

=head2 getgid

C<static method getgid : int ();>

Calls the L<getgid|https://linux.die.net/man/2/getgid> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. getgid is not supported in this system(defined(_WIN32)).

=head2 getegid

C<static method getegid : int ();>

Calls the L<getegid|https://linux.die.net/man/2/getegid> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. getegid is not supported in this system(defined(_WIN32)).

=head2 setuid

C<static method setuid : int ($uid : int);>

Calls the L<setuid|https://linux.die.net/man/2/setuid> function and returns its return value.

Exceptions:

If the setuid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. setuid is not supported in this system(defined(_WIN32)).

=head2 seteuid

C<static method seteuid : int ($euid : int);>

Calls the L<seteuid|https://linux.die.net/man/2/seteuid> function and returns its return value.

Exceptions:

If the seteuid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. seteuid is not supported in this system(defined(_WIN32)).

=head2 setgid

C<static method setgid : int ($gid : int);>

Calls the L<setgid|https://linux.die.net/man/2/setgid> function and returns its return value.

Exceptions:

If the setgid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. setgid is not supported in this system(defined(_WIN32)).

=head2 setegid

C<static method setegid : int ($egid : int);>

Calls the L<setegid|https://linux.die.net/man/2/setegid> function and returns its return value.

Exceptions:

If the setegid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. setegid is not supported in this system(defined(_WIN32)).

=head2 setpwent

C<static method setpwent : void ();>

Calls the L<setpwent|https://linux.die.net/man/3/setpwent> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. setpwent is not supported in this system(defined(_WIN32)).

=head2 endpwent

C<static method endpwent : void ();>

Calls the L<endpwent|https://linux.die.net/man/3/endpwent> function and returns its return value.

Exceptions:

In Windows the following exception is thrown. endpwent is not supported in this system(defined(_WIN32)).

=head2 getpwent

C<static method getpwent : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ();>

Calls the L<getpwent|https://linux.die.net/man/3/getpwent> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getpwent function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getpwent is not supported in this system(defined(_WIN32)).

=head2 setgrent

C<static method setgrent : void ();>

Calls the L<setgrent|https://linux.die.net/man/3/setgrent> function.

Exceptions:

In Windows the following exception is thrown. setgrent is not supported in this system(defined(_WIN32)).

=head2 endgrent

C<static method endgrent : void ();>

Calls the L<endgrent|https://linux.die.net/man/3/endgrent> function.

Exceptions:

In Windows the following exception is thrown. endgrent is not supported in this system(defined(_WIN32)).

=head2 getgrent

C<static method getgrent : L<Sys::User::Group|SPVM::Sys::User::Group> ();>

Calls the L<getgrent|https://linux.die.net/man/3/getgrent> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Group|SPVM::Sys::User::Group> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getgrent function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getgrent is not supported in this system(defined(_WIN32)).

=head2 getgroups

C<static method getgroups : int ($size : int, $list : int[]);>

Calls the L<getgroups|https://linux.die.net/man/2/getgroups> function, and returns its return value.

Exceptions:

If the getgroups function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getgroups is not supported in this system(defined(_WIN32)).

=head2 setgroups

C<static method setgroups : void ($groups : int[]);>

Calls the L<setgroups|https://linux.die.net/man/2/setgroups> function.

Exceptions:

If the setgroups function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. setgroups is not supported in this system(defined(_WIN32)).

=head2 getpwuid

C<static method getpwuid : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ($id : int);>

Calls the L<getpwuid|https://linux.die.net/man/3/getpwuid> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getpwuid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getpwuid is not supported in this system(defined(_WIN32)).

=head2 getpwnam

C<static method getpwnam : L<Sys::User::Passwd|SPVM::Sys::User::Passwd> ($name : string);>

Calls the L<getpwnam|https://linux.die.net/man/3/getpwnam> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getpwnam function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getpwnam is not supported in this system(defined(_WIN32)).

=head2 getgrgid

C<static method getgrgid : L<Sys::User::Group|SPVM::Sys::User::Group> ($id : int);>

Calls the L<getgrgid|https://linux.die.net/man/3/getgrgid> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Group|SPVM::Sys::User::Group> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getgrgid function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getgrgid is not supported in this system(defined(_WIN32)).

=head2 getgrnam

C<static method getgrnam : L<Sys::User::Group|SPVM::Sys::User::Group> ($name : string);>

Calls the L<getgrnam|https://linux.die.net/man/3/getgrnam> function.

And if its return value is NULL, returns undef, otherwise creates a new L<Sys::User::Group|SPVM::Sys::User::Group> object whose pointer is set to function's return value, and returns it.

Exceptions:

If the getgrnam function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

In Windows the following exception is thrown. getgrnam is not supported in this system(defined(_WIN32)).

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

