=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's constructors work.

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

use Set::Equivalence qw( set typed_set );

my $set = set( 1..5 );

isa_ok($set, 'Set::Equivalence');

is_deeply(
	+{%$set},
	{
		members               => [ 1..5 ],
		equivalence_relation  => \&Set::Equivalence::_default_equivalence_relation,
		mutable               => !!1,
	},
);

my $clone1 = 'Set::Equivalence'->clone($set);
my $clone2 = $set->clone;

is_deeply($clone1, $set);
is_deeply($clone2, $set);

ok( set->is_mutable, 'sets default to mutable' );
ok( set->make_immutable->is_immutable, 'make_immutable works' );
ok( set->make_immutable->clone->is_mutable, 'clones are always mutable' );

is_deeply(
	+{%{typed_set(0, 1)}},
	{
		members               => [ 1 ],
		equivalence_relation  => \&Set::Equivalence::_default_equivalence_relation,
		mutable               => !!1,
		type_constraint       => '0',
	},
	'typed_set',
);

done_testing;
