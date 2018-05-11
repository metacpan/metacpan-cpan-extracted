package OpusVL::Preferences::Schema::Result::CustomDataUniqueValues;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->table("prf_unique_vals");
__PACKAGE__->add_columns
(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    value_id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    value => {
        data_type => 'text',
        is_nullable => 1,
    },
	prf_owner_type_id =>
	{
		data_type   => "integer",
		is_nullable => 0,
	},
	name =>
	{
		data_type   => 'varchar',
		is_nullable => 0
	},
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint([ qw/value_id prf_owner_type_id name/ ]);
__PACKAGE__->add_unique_constraint([ qw/value prf_owner_type_id name/ ]);

__PACKAGE__->belongs_to(field =>
  "OpusVL::Preferences::Schema::Result::PrfDefault",
  { 
      "foreign.prf_owner_type_id" => "self.prf_owner_type_id", 
      "foreign.name" => "self.name", 
  });

__PACKAGE__->belongs_to(parent_value =>
  "OpusVL::Preferences::Schema::Result::PrfPreference",
  { 
      "foreign.prf_owner_type_id"   => "self.prf_owner_type_id", 
      "foreign.name"                => "self.name", 
      "foreign.prf_preference_id"   => "self.value_id" 
  });


1;

=head1 DESCRIPTION

I thought this was obvious until I realised it has a 'name' column and now I
have no idea what it does.

=head1 METHODS

=head1 ATTRIBUTES

=head2 id

=head2 value_id

=head2 value

=head2 field_id

=head2 field

=head2 parent_value


=head1 LICENSE AND COPYRIGHT

Copyright 2013 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=cut
