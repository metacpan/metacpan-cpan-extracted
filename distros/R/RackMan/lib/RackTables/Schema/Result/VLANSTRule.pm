package RackTables::Schema::Result::VLANSTRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::VLANSTRule

=cut

__PACKAGE__->table("VLANSTRule");

=head1 ACCESSORS

=head2 vst_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 rule_no

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 port_pcre

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 port_role

  data_type: 'enum'
  default_value: 'none'
  extra: {list => ["access","trunk","anymode","uplink","downlink","none"]}
  is_nullable: 0

=head2 wrt_vlans

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "vst_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "rule_no",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "port_pcre",
  { data_type => "char", is_nullable => 0, size => 255 },
  "port_role",
  {
    data_type => "enum",
    default_value => "none",
    extra => {
      list => ["access", "trunk", "anymode", "uplink", "downlink", "none"],
    },
    is_nullable => 0,
  },
  "wrt_vlans",
  { data_type => "char", is_nullable => 1, size => 255 },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
);
__PACKAGE__->add_unique_constraint("vst-rule", ["vst_id", "rule_no"]);

=head1 RELATIONS

=head2 vst

Type: belongs_to

Related object: L<RackTables::Schema::Result::VLANSwitchTemplate>

=cut

__PACKAGE__->belongs_to(
  "vst",
  "RackTables::Schema::Result::VLANSwitchTemplate",
  { id => "vst_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uN+1jvXyo+rFKKhXNhsjMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
