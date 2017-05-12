package OpusVL::AppKit::Schema::AppKitAuthDB::Result::Aclrule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");


__PACKAGE__->table("aclrule");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "actionpath",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->has_many(
  "aclrule_roles",
  "OpusVL::AppKit::Schema::AppKitAuthDB::Result::AclruleRole",
  { "foreign.aclrule_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-24 12:44:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ojOqRgaXbTe0r/fJD5L/Tg


use Moose;
use OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Aclrule;
with 'OpusVL::AppKit::RolesFor::Schema::AppKitAuthDB::Result::Aclrule';
__PACKAGE__->setup_authdb;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::Aclrule

=head1 VERSION

version 6

=head1 NAME

OpusVL::AppKit::Schema::AppKitAuthDB::Result::Aclrule

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 actionpath

  data_type: 'text'
  is_nullable: 0

=head1 RELATIONS

=head2 aclrule_roles

Type: has_many

Related object: L<OpusVL::AppKit::Schema::AppKitAuthDB::Result::AclruleRole>

=head1 AUTHOR

Colin Newell <colin@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
