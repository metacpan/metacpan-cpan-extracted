package OpusVL::Preferences;

use warnings;
use strict;

# ABSTRACT: Generic DBIC preferences module

our $VERSION = '0.29';



1; # End of OpusVL::Preferences

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::Preferences - Generic DBIC preferences module

=head1 VERSION

version 0.29

=head1 SYNOPSIS

This is a really simple module to pull into result classes so you can attach
preferences, rather than have to continually extend the schema definition where
its probably not appropriate.

Say you had an Employees class, and wanted to define the following preferences
for a customer:

=over

=item grows_plants

=item has_untidy_desk

=item likes_noodles

=back

You would set up your Result class as follows:

	package Result::Employee;

	use strict;
	use Moose;
	
	extends 'DBIx::Class::Core';

	with 'OpusVL::Preferences::RolesFor::Result::PrfOwner';

	__PACKAGE__->prf_owner_init;

	...

And the ResultSet class would be:

	package ResultSet::Employee;

	use strict;
	use Moose;

	extends 'DBIx::Class::ResultSet';

	with 'OpusVL::Preferences::RolesFor::ResultSet::PrfOwner';

	...

This would initialise the class with 3 preferences, set to the appropriate
defaults. Within the Employee class, the following methods are exposed to
manage the preferences:

=head2 Result Class Methods

=head3 prf_get

Get the current value of the preference (either the default or local copy as
appropriate).

	$p = $employee->prf_get ('grows_plants');    # $p == 1

=head3 prf_set

Overides the default preference value for the employee in question:

	$employee = prf_set (grows_plants => 0);
	$p = $employee->prf_get ('grows_plants');    # $p == 0

=head3 prf_reset

Deletes any local overrides and uses the default

	$employee->prf_reset ('grows_plants');
	$p = $employee->prf_get ('grows_plants');    # $p == 1

=head3 prf_preferences

Returns a resultset containing PrfPreference classes.

=head2 ResultSet Methods

=head3 prf_defaults

Returns a resultset of the default preferences setup for this resultset. Add
more results to this object to add more defaults. For example, the following
might be in the initdb routine:

	sub initdb
	{
		my $self = shift;

		$self->prf_defaults->populate
		([
			{ name => 'grown_plants'    => default_value => '1' },
			{ name => 'has_untidy_desk' => default_value => '1' },
			{ name => 'likes_noodles'   => default_value => '1' },
		]);
	}

=head3 prf_search

To be completed. Will allow an Employee resultset to be return using
preferences as a search parameter.

=head1 BUGS

None. Past, present and future.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpusVL::Preferences

If you require assistance, support, or further development of this software, please contact OpusVL using the details below:

=over 4

=item *

Telephone: +44 (0)1788 298 410

=item *

Email: community@opusvl.com

=item *

Web: L<http://opusvl.com>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
