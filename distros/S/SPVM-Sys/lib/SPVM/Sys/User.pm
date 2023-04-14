package SPVM::Sys::User;

1;

=head1 Name

SPVM::Sys::User - User System Call

=head1 Usage
  
  use Sys::User;
  
  my $effective_user_id = Sys::User->geteuid;

=head1 Description

C<Sys::User> is the class for the user manipulation.

=head1 Class Methods

=head2 getuid

  native static method getuid : int ()

Get the real user ID.

=head2 geteuid

  native static method geteuid : int ()
  
Get the effective user ID.

=head2 getgid

  native static method getgid : int ()

Get the real group ID.

=head2 getegid

  native static method getegid : int ()
  
Get the effective group ID.

=head2 setuid

  native static method setuid : int ($uid : int)

Set the user ID.

=head2 seteuid

  native static method seteuid : int ($euid : int)

Set the effective user ID.

=head2 setgid

  native static method setgid : int ($gid : int)

Set the real user ID.

=head2 setegid

  native static method setegid : int ($egid : int)

Set the effective group ID.

=head2 setpwent

  native static method setpwent : void ()

Move to the head of the group database.

=head2 endpwent

  native static method endpwent : void ()

Close the group database.

=head2 getpwent

  native static method getpwent : Sys::User::Passwd ()

Get a group entry. The group entry is a L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object.

=head2 setgrent

  native static method setgrent : void ()

Move to the head of the group database.

=head2 endgrent

  native static method endgrent : void ()

Close the group database.

=head2 getgrent

  native static method getgrent : Sys::User::Group ()

Get a group entry as L<Sys::User::Group|SPVM::Sys::User::Group>

=head2 getgroups

  native static method getgroups : int[] ()

Get group IDs.

=head2 setgroups

  native static method setgroups : void ($groups : int[])

Set group IDs.

=head2 getpwuid

  native static method getpwuid : Sys::User::Passwd ($id : int)

Get a group entry by the user id. The group entry is a L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object.

=head2 getpwnam

  native static method getpwnam : Sys::User::Passwd ($name : string)

Get a group entry by the user name. The group entry is a L<Sys::User::Passwd|SPVM::Sys::User::Passwd> object.

=head2 getgrgid

  native static method getgrgid : Sys::User::Group ($id : int)

Get a group entry by the user id. The group entry is a L<Sys::User::Group|SPVM::Sys::User::Group> object.

=head2 getgrnam

  native static method getgrnam : Sys::User::Group ($name : string)

Get a group entry by the user id. The group entry is a L<Sys::User::Group|SPVM::Sys::User::Group> object.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

