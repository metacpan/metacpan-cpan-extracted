package OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("users_role");


__PACKAGE__->add_columns(
  "users_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "role_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
);
__PACKAGE__->set_primary_key("users_id", "role_id");


__PACKAGE__->belongs_to(
  "role",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::Role",
  { id => "role_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


__PACKAGE__->belongs_to(
  "user",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::User",
  { id => "users_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-24 11:55:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UVVZaKhAChYZ6iGh5FTKvQ

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersRole

=head1 VERSION

version 6

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersRole

=head1 ACCESSORS

=head2 users_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::Role>

=head2 user

Type: belongs_to

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::User>

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
