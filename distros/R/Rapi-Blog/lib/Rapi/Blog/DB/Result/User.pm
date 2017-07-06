use utf8;
package Rapi::Blog::DB::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "full_name",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 64,
  },
  "image",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "email",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "admin",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "author",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "comment",
  { data_type => "boolean", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("full_name_unique", ["full_name"]);
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);
__PACKAGE__->has_many(
  "comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_authors",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.author_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_creators",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.creator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_updaters",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.updater_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-06-16 23:59:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CsDZyGJU9o2NZP7vE2Wz9Q

use RapidApp::Util ':all';

__PACKAGE__->load_components('+RapidApp::DBIC::Component::TableSpec');
__PACKAGE__->load_components('+Rapi::Blog::DB::Component::SafeResult');

__PACKAGE__->add_virtual_columns( set_pw => {
  data_type => "varchar", 
  is_nullable => 1, 
  sql => "SELECT NULL",
  set_function => sub {} # This is a dummy designed to hook via AuthCore/linked_user_model
});

__PACKAGE__->apply_TableSpec;


sub insert {
  my $self = shift;

  # Fix GitHub Issue #1 - we want to do this perm check, however, if this insert is being
  # generated via automatic inflation from the CoreSchema LinkedRow, this will result in
  # a deep recursion (i.e. the current user *is* being inserted). For this case, we bail
  # out of the perm check if we detect that a linkedRow sync is already in-progress
  unless($self->{_pulling_linkedRow}) {
    my $User = Rapi::Blog::Util->get_User;
    die usererr "Create User: PERMISSION DENIED" if ($User && $User->id && !$User->admin);
  }
	
  $self->next::method(@_);
  
  $self->_role_perm_sync;

  $self
}

sub update {
  my $self = shift;
	
  my $User = Rapi::Blog::Util->get_User;
	
  die usererr "Update User: PERMISSION DENIED" if (
		$User && $User->id && 
		!($User->admin || $self->id == $User->id)
  );
	
  $self->next::method(@_);
  
  $self->_role_perm_sync;

  $self
}

sub delete {
	my $self = shift;
	
  my $User = Rapi::Blog::Util->get_User;
  die usererr "Delete User: PERMISSION DENIED" if ($User && $User->id && !$User->admin);
	
  $self->next::method(@_)
}


# return the username if full_name is not set
around 'full_name' => sub {
  my ($orig,$self,@args) = @_;
  $self->$orig(@args) || $self->username
};

sub image_url {
  my $self = shift;
  $self->{_image_url} //= $self->image 
    ? join('/','_ra-rel-mnt_','simplecas','fetch_content',$self->image) 
    : undef
}

sub _role_perm_sync {
  my $self = shift;
  
  if($self->{_pulling_linkedRow}) {
    $self->_apply_from_CoreUser($self->{_pulling_linkedRow});
  }
  else {
    if($self->can('_find_linkedRow')) {
      # This is ugly but needed to hook both sides correctly across all CRUD ops
      my $Row = $self->_find_linkedRow || $self->_create_linkedRow;
      $self->_apply_to_CoreUser( $Row );
    }
  }
}



# change originated from CoreSchema::User:
sub _apply_from_CoreUser {
  my ($self, $CoreUser) = @_;
  
  my $cur_admin = $self->admin || 0;
  
  $CoreUser = $CoreUser->get_from_storage if ($CoreUser->in_storage); # needed in case the username has changed

  my $LinkRs = $CoreUser->user_to_roles;
  my $admin_cond = { username => $CoreUser->username, role => 'administrator' };
  if($LinkRs->search_rs($admin_cond)->first) {
    $self->admin(1);
  }
  else {
    $self->admin(0);
  }
  
  $self->update unless ($cur_admin == $self->admin);
}



# change originated locally:
sub _apply_to_CoreUser {
  my ($self, $CoreUser) = @_;
  
  my $LinkRs = $CoreUser->user_to_roles;
  my $admin_cond = { username => $CoreUser->username, role => 'administrator' };
  if($self->admin) {
    $LinkRs->find_or_create($admin_cond);
  }
  else {
    if(my $Link = $LinkRs->search_rs($admin_cond)->first) {
      $Link->delete;
    }
  }

}


sub can_post {
  my $self = shift;
  $self->admin || $self->author
}

sub can_comment {
  my $self = shift;
  $self->admin || $self->comment
}



# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Rapi::Blog::DB::Result::User - User row object

=head1 DESCRIPTION

This is the default User Result class/row object for L<Rapi::Blog>. The C<list_users()> template directive
returns an array of these objects (in the sub property C<rows>)


This is a L<DBIx::Class::Row>.

=head1 COLUMNS

=head2 id

Auto-increment user id. Read-only.

=head2 username

The unique username used to login to the system. This links with the RapidApp AuthCore user object with
the same username and the system automatically keeps these objects in sync.

=head2 full_name

Friendly display name.

=head2 image

CAS image column (C<'cas_img'>). Contains the sha1 of a file within the SimpleCAS.

=head2 email

User's E-Mail address

=head2 admin

True/false permission flag if the user is an admin or not. Setting this value automatically adds or 
removes the C<administrators> role in AuthCore user object.

=head2 author

True/false permission flag which determines whether or not a user is allowed to add new posts.

=head2 comment

True/false permission flag which determines whether or not a user is allowed to add comments.

=head2 set_pw

Virtual column can be set with a plaintext value that on insert/update will store the hashed
password in the AuthCore user row.

=head1 METHODS

=head2 image_url 

URL which can be used to access the user's C<image> (i.e. avatar) for the active site/scaffold.

=head2 can_post 

Util method returns true if the user can post. Will be true if the user is either an admin or
an author.

=head2 can_post 

Util method returns true if the user can comment. Will be true if the user is either an admin or
has the comment permission.

=head2 comments 

Multi-relationship to all the Comments this user has created.

=head2 post_authors

Multi-relationship to all the Posts this user is the author of.

=head2 post_creators

Multi-relationship to all the Posts this user has created.

=head2 post_updaters

Multi-relationship to all the Posts this user is the last updater of.


=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item *

L<http://rapi.io/blog>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
