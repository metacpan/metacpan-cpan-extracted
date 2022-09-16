package SPVM::Sys::User::Group;

1;

=head1 Name

SPVM::Sys::User::Group - Entry of Group Database

=head1 Usage
  
  use Sys::User;
  use Sys::User::Group;
  
  Sys::User->setgrent;
  
  # Get a Sys::User::Group object
  my $group = Sys::User->getgrent;
  
  my $group_name = $group->gr_name;
  
  Sys::User->endgrent;

=head1 Description

C<Sys::User::Group> is the class for an entry of the group database.

=head2 gr_name

  method gr_name : string ();

Get the group name.

=head2 gr_passwd

  method gr_passwd : string ();

Get the group password.

=head2 gr_gid

  method gr_gid : int ();

Get the group ID.

=head2 gr_mem

  method gr_mem : string[] ();

Get the group member names.
