package SPVM::Sys::User::Passwd;

1;

=head1 Name

SPVM::Sys::User::Passwd - Entry of Password Database

=head1 Usage
  
  use Sys::User;
  use Sys::User::Passwd;
  
  Sys::User->setpwent;
  
  # Get a Sys::User::Passwd object
  my $password = Sys::User->getpwent;
  
  my $user_name = $password->pw_name;
  
  Sys::User->endpwent;

=head1 Description

C<Sys::User::Passwd> is the class for an entry of the password database.

=head1 Class Methods

=head2 pw_name

C<method pw_name : string ();>

Get the user name.

=head2 pw_passwd

C<method pw_passwd : string ();>

Get the user password.

=head2 pw_uid

C<method pw_uid : int ();>

Get the user id.

=head2 pw_gid

C<method pw_gid : int ();>

Get the group id.

=head2 pw_gecos

C<method pw_gecos : string ();>

Get the user information.

=head2 pw_dir

C<method pw_dir : string ();>

Get the home directory.

=head2 pw_shell

C<method pw_shell : string ();>

Get the shell program.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

