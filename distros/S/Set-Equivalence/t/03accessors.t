=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's accessors work.

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
use Data::Dumper qw(Dumper);
use Scalar::Util qw(refaddr);

my $set = Set::Equivalence->new(
	members         => [ 1..5 ],
	type_constraint => '0',
);

is_deeply(
	[ sort $set->members ],
	[ sort 1..5 ],
);

is_deeply(
	[ sort $set->elements ],
	[ sort 1..5 ],
);

is(
	$set->size,
	5,
);

is(
	$set->member(4),
	4,
);

is(
	$set->member(6),
	undef,
);

is(
	$set->element(4),
	4,
);

is(
	$set->element(6),
	undef,
);

is_deeply(
	[$set->member(4)],
	[4],
);

is_deeply(
	[$set->member(6)],
	[],
);

is_deeply(
	[$set->element(4)],
	[4],
);

is_deeply(
	[$set->element(6)],
	[],
);

is(
	refaddr($set->equivalence_relation),
	refaddr(\&Set::Equivalence::_default_equivalence_relation),
);

is(
	Dumper($set->type_constraint),
	Dumper('0'),
);

done_testing;
