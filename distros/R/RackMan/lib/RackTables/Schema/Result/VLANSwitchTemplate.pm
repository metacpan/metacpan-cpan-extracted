package RackTables::Schema::Result::VLANSwitchTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

RackTables::Schema::Result::VLANSwitchTemplate

=cut

__PACKAGE__->table("VLANSwitchTemplate");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 mutex_rev

  data_type: 'integer'
  is_nullable: 0

=head2 description

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 saved_by

  data_type: 'char'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "mutex_rev",
  { data_type => "integer", is_nullable => 0 },
  "description",
  { data_type => "char", is_nullable => 1, size => 255 },
  "saved_by",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("description", ["description"]);

=head1 RELATIONS

=head2 vlanstrules

Type: has_many

Related object: L<RackTables::Schema::Result::VLANSTRule>

=cut

__PACKAGE__->has_many(
  "vlanstrules",
  "RackTables::Schema::Result::VLANSTRule",
  { "foreign.vst_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlanswitches

Type: has_many

Related object: L<RackTables::Schema::Result::VLANSwitch>

=cut

__PACKAGE__->has_many(
  "vlanswitches",
  "RackTables::Schema::Result::VLANSwitch",
  { "foreign.template_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-26 11:34:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nE98Nb3OjV6JdVrVm7heSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
