=pod

=encoding utf-8

=head1 PURPOSE

Test that sets can have type coercions.

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
use Test::Fatal;

use Set::Equivalence qw(set);
use Types::Standard qw(-types);

my $set = 'Set::Equivalence'->new(
	type_constraint => ArrayRef[ Int->plus_coercions(Num, q{int($_)}) ],
	coerce          => !!1,
);

my @arrays = (
	[ 1, 2 ],
	[ 3.14159 ],
	[ 4, 5.5, 6, 7 ],
	[ ],
);

$set->insert(@arrays);

is_deeply(
	[ sort { scalar(@$a) <=> scalar(@$b) } $set->members ],
	[ [], [3], [1..2], [4..7] ]
);

done_testing;
