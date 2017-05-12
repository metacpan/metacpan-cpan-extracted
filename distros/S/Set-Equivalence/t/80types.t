=pod

=encoding utf-8

=head1 PURPOSE

Test constraints from Types::Set.

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
use Test::TypeTiny;

use Set::Equivalence qw( set typed_set );
use Types::Standard -types;
use Types::Set -types;

should_pass( set(1...5), AnySet );
should_fail( [], AnySet );

for my $data ([], [1], [1..10]) {
	should_pass( set(@$data), Set );
	should_pass( typed_set(Int, @$data), Set );
	should_fail( $data, Set );
	should_pass( set(@$data)->make_immutable, Set );

	should_pass( set(@$data), MutableSet );
	should_pass( typed_set(Int, @$data), MutableSet );
	should_fail( $data, MutableSet );
	should_fail( set(@$data)->make_immutable, MutableSet );

	should_fail( set(@$data), ImmutableSet );
	should_fail( typed_set(Int, @$data), ImmutableSet );
	should_fail( $data, ImmutableSet );
	should_pass( set(@$data)->make_immutable, ImmutableSet );
}

should_fail( set(1...5), Set[Num] );
should_fail( typed_set(Any, 1...5), Set[Num] );
should_pass( typed_set(Num, 1...5), Set[Num] );
should_pass( typed_set(Int, 1...5), Set[Num] );
should_fail( set(1...5)->make_immutable, Set[Num] );
should_fail( typed_set(Any, 1...5)->make_immutable, Set[Num] );
should_pass( typed_set(Num, 1...5)->make_immutable, Set[Num] );
should_pass( typed_set(Int, 1...5)->make_immutable, Set[Num] );

should_fail( set(1...5), MutableSet[Num] );
should_fail( typed_set(Any, 1...5), MutableSet[Num] );
should_pass( typed_set(Num, 1...5), MutableSet[Num] );
should_pass( typed_set(Int, 1...5), MutableSet[Num] );
should_fail( set(1...5)->make_immutable, MutableSet[Num] );
should_fail( typed_set(Any, 1...5)->make_immutable, MutableSet[Num] );
should_fail( typed_set(Num, 1...5)->make_immutable, MutableSet[Num] );
should_fail( typed_set(Int, 1...5)->make_immutable, MutableSet[Num] );

should_fail( set(1...5), ImmutableSet[Num] );
should_fail( typed_set(Any, 1...5), ImmutableSet[Num] );
should_fail( typed_set(Num, 1...5), ImmutableSet[Num] );
should_fail( typed_set(Int, 1...5), ImmutableSet[Num] );
should_fail( set(1...5)->make_immutable, ImmutableSet[Num] );
should_fail( typed_set(Any, 1...5)->make_immutable, ImmutableSet[Num] );
should_pass( typed_set(Num, 1...5)->make_immutable, ImmutableSet[Num] );
should_pass( typed_set(Int, 1...5)->make_immutable, ImmutableSet[Num] );

done_testing;

