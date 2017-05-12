=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's predicate methods work.

C<is_mutable> and C<is_immutable> are tested in 02constructors.t.

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

use Set::Equivalence qw(set);

ok( set->is_null, 'empty set is null' );

my $set = Set::Equivalence->new(
	members         => [ 1..5 ],
	type_constraint => '0',
);

ok( !$set->is_null, 'non-empty set is not null' );

ok( !$set->is_weak, 'sets are strong' );

ok( $set->contains(), 'contains() returns true' );

ok( $set->contains(2), 'contains($member)' );

ok( $set->includes(2), 'includes($member)' );

ok( $set->has(2), 'has($member)' );

ok( $set->contains(2, 3), 'contains(@members)' );

ok( !$set->contains(2..10), 'contains(@mixed)' );

ok( !$set->contains(8..10), 'contains(@nonmembers)' );

ok( !$set->contains(10), 'contains($nonmember)' );

ok( !$set->contains(undef), 'contains(undef)' );

ok( set(undef)->contains(undef), 'set(undef)->contains(undef)' );

done_testing;
