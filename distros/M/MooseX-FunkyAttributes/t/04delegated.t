=pod

=encoding utf-8

=head1 PURPOSE

Check the C<DelegatedAttribute> trait works using a C<House> class which
delegates its C<door_bell> attribute to its C<door>'s C<bell> attribute.

Checks with both mutable and immutable class.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN {
	package Local::Bell;
	no thanks;
	use Moose;
	sub ring { return "ring ring!" };
}

BEGIN {
	package Local::Door;
	no thanks;
	use Moose;
	has bell => (
		is         => 'rw',
		isa        => 'Object',
		lazy_build => 1,
	);
	sub _build_bell { Local::Bell->new };
}

BEGIN {
	package Local::House;
	no thanks;
	use Moose;
	use MooseX::FunkyAttributes;
	has door => (
		is         => 'rw',
		isa        => 'Object',
		lazy_build => 1,
	);
	has door_bell => (
		traits     => [ DelegatedAttribute ],
		is         => 'rw',
		isa        => 'Object',
		clearer    => 'clear_door_bell',
		predicate  => 'has_door_bell',
		delegated_to         => 'door',
		delegated_accessor   => 'bell',
	);
	sub _build_door { Local::Door->new };
}

#######################################################################

use Test::More;
use Scalar::Util qw(refaddr);

for my $iter (0 .. 1)
{
	my $house = Local::House->Test::More::new_ok;

	ok(!$house->has_door, q[!$house->has_door]);
	ok(!$house->has_door_bell, q[!$house->has_door_bell]);
	ok($house->has_door, q[$house->has_door (auto-viv)]);

	is(
		refaddr($house->door->bell),
		refaddr($house->door_bell),
		'object refs identical',
	);
	
	is(
		Local::House->meta->find_attribute_by_name('door_bell')->delegated_to,
		'door',
		'introspection: delegated_to',
	);

	is(
		Local::House->meta->find_attribute_by_name('door_bell')->delegated_accessor,
		'bell',
		'introspection: delegated_accessor',
	);

	is(
		Local::House->meta->find_attribute_by_name('door_bell')->delegated_clearer,
		'clear_bell', # as a
		'introspection: delegated_clearer',
	);

	is(
		Local::House->meta->find_attribute_by_name('door_bell')->delegated_predicate,
		'has_bell', # as a
		'introspection: delegated_predicate',
	);

	unless ($iter)
	{
		note 'same again, but immutable!';
		$_->meta->make_immutable for qw( Local::Bell Local::Door Local::House );
	}
}

done_testing();
