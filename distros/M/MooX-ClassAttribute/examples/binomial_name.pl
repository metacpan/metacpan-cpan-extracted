=head1 PURPOSE

Demonstrate fairly typical usage of a class attribute.

=head1 EXPECTED OUTPUT

 Robert
 Homo sapiens

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

{
	package Local::Life;
	use Moo::Role;
	use MooX::ClassAttribute;
	class_has binomial_name => (is => 'rwp');
}

{
	package Local::Person;
	use Moo;
	with 'Local::Life';
	__PACKAGE__->_set_binomial_name('Homo sapiens');
	has name => (is => 'ro');
}

my $bob = Local::Person->new(name => 'Robert');
say $bob->name;
say $bob->binomial_name;
