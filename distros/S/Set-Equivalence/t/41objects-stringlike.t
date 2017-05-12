=pod

=encoding utf-8

=head1 PURPOSE

Test that objects overloading stringification can be stored in sets.

=head1 DEPENDENCIES

This test requires L<Type::Tiny> 0.014 and is skipped otherwise. We don't
really need type constraints, but Type::Tiny overloads stringification, so
is handy here.

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
use Test::Requires { 'Types::Standard' => '0.014' };

use Set::Equivalence qw(set);
use Types::Standard qw(-types);

is( set(Str, Str->no_coercions, "Str")->size, 1 );

is( set(Str, 'Type::Tiny'->new(name => 'Str'))->size, 1 );

my @types = (
	Str,
	Str->no_coercions,
	Int,
	Int->create_child_type(name => 'Bomb'),
	ArrayRef,
	'Type::Tiny'->new(name => 'ArrayRef'),
);

my $set = 'Set::Equivalence'->new(
	equivalence_relation => sub { $_[0] == $_[1] },
	members              => \@types,
);

is($set->size, 4);

is_deeply(
	[ sort { $a->{uniq} <=> $b->{uniq} } $set->members ],
	[ sort { $a->{uniq} <=> $b->{uniq} } Str, Int, ArrayRef, $types[-1] ],
);

done_testing;
