=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::ClosedHash compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Moose;

{
	package Person;
	use MooseX::ClosedHash;
	has name => (is => "rw");
	has age  => (is => "rw");
}

{
	package Employee;
	use MooseX::ClosedHash;
	extends qw(Person);
	has id   => (is => "rw");
}

use Scalar::Util qw(reftype);

with_immutable {
	my $bob = Person->new(name => "Bob", age => 42);
	is(reftype($bob), q(CODE), 'reftype($bob)');
	is($bob->name, "Bob", '$bob->name');
	is($bob->age, 42, '$bob->age');
	is($bob->age(43), 43, '$bob->age(43)');
	is($bob->age, 43, '$bob->age');
	
	my $alice = Employee->new(name => "Alice", id => 123456);
	is(reftype($alice), q(CODE), 'reftype($alice)');
	is($alice->id, 123456, '$alice->id');
	is($alice->age, undef, '$alice->age');
} qw( Person Employee );

done_testing;

