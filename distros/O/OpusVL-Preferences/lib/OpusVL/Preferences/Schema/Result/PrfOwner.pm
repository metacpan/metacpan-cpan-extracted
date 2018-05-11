
package OpusVL::Preferences::Schema::Result::PrfOwner;

use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

__PACKAGE__->table("prf_owners");

__PACKAGE__->add_columns
(
	prf_owner_id =>
	{
		data_type   => "integer",
		is_nullable => 0
	},

	prf_owner_type_id =>
	{
		data_type   => "integer",
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key("prf_owner_id", "prf_owner_type_id");


__PACKAGE__->has_many
(
	prf_preferences => "OpusVL::Preferences::Schema::Result::PrfPreference",
	{
		"foreign.prf_owner_id"      => "self.prf_owner_id",
		"foreign.prf_owner_type_id" => "self.prf_owner_type_id",
	}, 
    { join_type => 'left' }
);

__PACKAGE__->belongs_to
(
	prf_owner_types => 'OpusVL::Preferences::Schema::Result::PrfOwnerType',
	{
		'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
	}
);

__PACKAGE__->has_many
(
    _by_name => 'OpusVL::Preferences::Schema::Result::PrfPreference',
    sub {
        my $args = shift;
        return (
            {
                "$args->{foreign_alias}.prf_owner_id"      => { -ident => "$args->{self_alias}.prf_owner_id" },
                "$args->{foreign_alias}.prf_owner_type_id" => { -ident => "$args->{self_alias}.prf_owner_type_id" },
                "$args->{foreign_alias}.name"              => \"= ?",
            }
        );
    },
);


return 1;


=head1 DESCRIPTION

This table associates PrfOwnerTypes with actual objects from the corresponding
table. The C<owner_id> tells us which object it is, and the C<owner_type_id>
links to the PrfOwnerType class, which tells us which table and resultset it is.

I don't know why it's necessary to store which rows from the host table have a
preferences object stored against them, without also storing that preferences
object in the same place.

=head1 METHODS

=head1 ATTRIBUTES

=head2 prf_preferences

=head2 prf_owner_types

=head2 prf_owner_id

=head2 prf_owner_type_id


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
