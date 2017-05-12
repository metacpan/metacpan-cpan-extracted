=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's mutator methods work.

C<make_immutable> is also tested in 02constructors.t.

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
use Test::Fatal;

use Set::Equivalence qw(set);

ok( set->is_null, 'empty set is null' );

my $set = set(1..5);
is($set->insert(4..10), 5);

is($set->size, 10);

is_deeply(
	[ sort $set->members ],
	[ sort 1..10 ],
);

is($set->remove(-10..2), 2);
is($set->delete(3), 1);

is($set->size, 7);

is_deeply(
	[ sort $set->members ],
	[ sort 4..10 ],
);

$set->invert(9..15);

is($set->size, 10);

is_deeply(
	[ sort $set->members ],
	[ sort 4..8, 11..15 ],
);

$set->pop;

is($set->size, 9);

is(set->pop, undef);
is(set(42)->pop, 42);

ok(not $set->is_null);
ok(not $set->is_empty);

$set->clear;

is($set->size, 0);

ok($set->is_null);
ok($set->is_empty);

is_deeply(
	[ $set->members ],
	[ ],
);

$set->make_immutable;

ok exception { $set->insert };
ok exception { $set->remove };
ok exception { $set->clear };

done_testing;
