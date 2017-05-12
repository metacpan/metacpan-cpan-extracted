=head1 PURPOSE

Demonstrate subtleties of L<MooX::CaptainHook>'s C<on_application>.

=head1 EXPECTED OUTPUT

 Local::Person
 Local::Document

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.010;
use strict;
use warnings;

# This role provides one method (TO_JSON).
# The role keeps a list of what classes compose it.
{
	package Local::Storable;
	use Moo::Role;
	use MooX::CaptainHook -all;
	sub TO_JSON { +{ %{ $_[0] } } }
	on_application {
		push our(@IMPLEMENTATIONS), $_ unless is_role $_;
	};
}

# "Local::Person" gets pushed onto @IMPLEMENTATIONS
# because it composes Local::Storable.
{
	package Local::Person;
	use Moo;
	with 'Local::Storable';
	has name => (is => 'rwp');
}

# "Local::Employee" is NOT pushed onto @IMPLEMENTATIONS
# because it doesn't compose Local::Storable. It just happens
# to inherit from a class that does.
{
	package Local::Employee;
	use Moo;
	extends 'Local::Person';
	has title => (is => 'rwp');
}

# This won't get listed in @IMPLEMENTATIONS because the
# on_application callback checks is_role($_).
{
	package Local::Storable::ToFile;
	use Moo::Role;
	with 'Local::Storable';
	use JSON;
	sub to_file {
		my ($self, $name) = @_;
		open my $fh, '>', $name;
		print {$fh} JSON::to_json($self, { convert_blessed => 1 });
	}
}

# This will get listed in @IMPLEMENTATIONS because it
# consumes Local::Storable (albeit indirectly).
{
	package Local::Document;
	use Moo;
	with 'Local::Storable::ToFile';
	has title => (is => 'rwp');
}

say for @Local::Storable::IMPLEMENTATIONS;
