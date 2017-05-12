=head1 PURPOSE

Basic example showing how to store one attribute inside out.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.14;

package Person {
	use Moose;
	use MooseX::FunkyAttributes;

	has name => (
		traits => [ InsideOutAttribute ],
		is     => 'ro',
		isa    => 'Str',
	);

	has age => (
		is     => 'ro',
		isa    => 'Num',
	);
}

my $bob = Person->new(name => 'Bob', age => 32);
say $bob->name;     # Bob
say $bob->dump;

