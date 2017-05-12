package OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("parameter");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "data_type",
  { data_type => "text", is_nullable => 0 },
  "parameter",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->has_many(
  "parameter_defaults",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::ParameterDefault",
  { "foreign.parameter_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
  "users_parameters",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersParameter",
  { "foreign.parameter_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-24 12:44:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5JfGAXTv11j54ikGYSKpuQ

use Moose;
use OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Parameter;
with 'OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Parameter';
__PACKAGE__->setup_authdb;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter

=head1 VERSION

version 6

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::Parameter

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 data_type

  data_type: 'text'
  is_nullable: 0

=head2 parameter

  data_type: 'text'
  is_nullable: 0

=head1 RELATIONS

=head2 parameter_defaults

Type: has_many

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::ParameterDefault>

=head2 users_parameters

Type: has_many

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::UsersParameter>

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
