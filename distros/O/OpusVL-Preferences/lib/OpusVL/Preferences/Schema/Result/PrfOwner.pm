
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

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::Schema::Result::PrfOwner

=head1 VERSION

version 0.27

=head1 DESCRIPTION

=head1 METHODS

=head1 ATTRIBUTES

=head2 prf_preferences

=head2 prf_owner_types

=head2 prf_owner_id

=head2 prf_owner_type_id

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
