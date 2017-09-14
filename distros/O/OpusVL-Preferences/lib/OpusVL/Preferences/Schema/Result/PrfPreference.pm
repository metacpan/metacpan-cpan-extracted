
package OpusVL::Preferences::Schema::Result::PrfPreference;

use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::Core';

__PACKAGE__->table("prf_preferences");

__PACKAGE__->add_columns
(
	prf_preference_id =>
	{
		data_type   => "integer",
		is_nullable => 0,
		is_auto_increment => 1
	},

	prf_owner_id =>
	{
		data_type   => 'integer',
		is_nullable => 0
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

	value =>
	{
		data_type   => 'varchar',
		is_nullable => 1
	},
);

__PACKAGE__->set_primary_key("prf_preference_id");

__PACKAGE__->add_unique_constraint([ qw/prf_preference_id prf_owner_type_id name/ ]);

__PACKAGE__->belongs_to
(
	prf_owner => 'OpusVL::Preferences::Schema::Result::PrfOwner',
	{
		'foreign.prf_owner_id'      => 'self.prf_owner_id',
		'foreign.prf_owner_type_id' => 'self.prf_owner_type_id'
	}
);

__PACKAGE__->might_have(unique_value =>
  "OpusVL::Preferences::Schema::Result::CustomDataUniqueValues",
    { 
      "foreign.prf_owner_type_id"   => "self.prf_owner_type_id", 
      "foreign.name"                => "self.name", 
      "foreign.value_id"            => "self.prf_preference_id" 
    },
  { is_foreign_key_constraint => 0, cascade_delete => 1 });


return 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::Schema::Result::PrfPreference

=head1 VERSION

version 0.27

=head1 DESCRIPTION

=head1 METHODS

=head1 ATTRIBUTES

=head2 prf_owner

=head2 prf_preference_id

=head2 prf_owner_id

=head2 prf_owner_type_id

=head2 name

=head2 value

=head1 LICENSE AND COPYRIGHT

Copyright 2012 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
