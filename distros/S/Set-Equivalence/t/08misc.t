=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's other miscellaneous methods.

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

my $forwards  = set(1..5);
my $backwards = set(5, 4, 3, 2, 1);

ok($forwards->equal($backwards), 'unordered');

is($forwards->as_string, "(1 2 3 4 5)");
is($backwards->as_string, "(1 2 3 4 5)");

($main::a, $main::b) = (0..0);
($main::a, $main::b) = (0..0);

is($forwards->reduce(sub { $a + $b }), 15, 'reduce');

my $iterator = $forwards->iterator;
my @members;
while (my $item = $iterator->()) {
	push @members, $item;
}

is_deeply(
	[ sort @members ],
	[ sort $forwards->members ],
	'iterator',
);

done_testing;
