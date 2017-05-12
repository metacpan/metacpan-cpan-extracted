
package OpusVL::Preferences::Schema::ResultSet::PrfOwnerType;

use strict;
use warnings;
use Moose;

extends 'DBIx::Class::ResultSet';

sub setup_from_source
{
	my $self   = shift;
	my $source = shift;

	my $table  = $source->from;
	my $rs     = $source->source_name;

	my $type = $self->get_from_source ($source);

	unless ($type)
	{
		$type = $self->create
		({
			owner_table     => $table,
			owner_resultset => $rs
		});
	}

	return $type;
}

sub get_from_source
{
	my $self   = shift;
	my $source = shift;

	my $table  = $source->from;
	my $rs     = $source->source_name;

	return $self->find
	({
		owner_table     => $table,
		owner_resultset => $rs
	});
}

return 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences::Schema::ResultSet::PrfOwnerType

=head1 VERSION

version 0.26

=head1 DESCRIPTION

=head1 METHODS

=head2 setup_from_source

=head2 get_from_source

=head1 ATTRIBUTES

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
