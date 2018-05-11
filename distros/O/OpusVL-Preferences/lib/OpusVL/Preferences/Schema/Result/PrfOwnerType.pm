
package OpusVL::Preferences::Schema::Result::PrfOwnerType;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

__PACKAGE__->table ("prf_owner_type");

__PACKAGE__->add_columns
(
	prf_owner_type_id =>
	{
		data_type   => 'integer',
		is_nullable => 0,
		is_auto_increment => 1,
	},

	owner_table => 
	{
		data_type   => 'varchar',
		is_nullable => 0,
	},

	owner_resultset =>
	{
		data_type   => 'varchar',
		is_nullable => 0
	}
);

__PACKAGE__->set_primary_key ('prf_owner_type_id');

__PACKAGE__->add_unique_constraints
(
	prf_owner_type__table     => ['owner_table'],
	prf_owner_type__resultset => ['owner_resultset'],
);

__PACKAGE__->has_many
(
	prf_owners => 'OpusVL::Preferences::Schema::Result::PrfOwner',
	{
		'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
	},
);

__PACKAGE__->has_many
(
	prf_defaults => 'OpusVL::Preferences::Schema::Result::PrfDefault',
	{
		'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
	},
);

return 1;


=head1 DESCRIPTION

This table for some reason stores an association between a table name, a
resultset name, and a sequential ID. These correspond to the classes in the host
database that are C<PrfOwner>s.

This appears to be entirely so that we can use numbers instead of letters
everywhere else.


=head1 METHODS

=head1 ATTRIBUTES

=head2 prf_owners

=head2 prf_defaults

=head2 prf_owner_type_id

=head2 owner_table

=head2 owner_resultset


=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
