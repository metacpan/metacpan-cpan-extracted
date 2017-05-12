package OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("users_parameter");


__PACKAGE__->add_columns(
  "users_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "parameter_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "value",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("users_id", "parameter_id");


__PACKAGE__->belongs_to(
  "parameter",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter",
  { id => "parameter_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


__PACKAGE__->belongs_to(
  "user",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::User",
  { id => "users_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-24 11:55:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YLYPXNQEOKveZfYOnMwTuQ

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersParameter

=head1 VERSION

version 6

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersParameter

=head1 ACCESSORS

=head2 users_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 parameter_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 0

=head1 RELATIONS

=head2 parameter

Type: belongs_to

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter>

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
