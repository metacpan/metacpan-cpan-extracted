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

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::Schema::Result::CustomDataUniqueValues

=head1 VERSION

version 0.27

=head1 DESCRIPTION

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

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
