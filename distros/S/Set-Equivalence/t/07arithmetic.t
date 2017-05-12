=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's arithmetic methods work.
(Think: Venn diagrammes.)

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

my $small = set(1..6);
my $big   = set(5..10);

is_deeply(
	[ sort $small->union($big)->members ],
	[ sort 1..10 ],
);

is_deeply(
	[ sort $big->union($small)->members ],
	[ sort 1..10 ],
);

is_deeply(
	[ sort $small->intersection($big)->members ],
	[ sort 5..6 ],
);

is_deeply(
	[ sort $big->intersection($small)->members ],
	[ sort 5..6 ],
);

is_deeply(
	[ sort $small->difference($big)->members ],
	[ sort 1..4 ],
);

is_deeply(
	[ sort $big->difference($small)->members ],
	[ sort 7..10 ],
);

is_deeply(
	[ sort $small->symmetric_difference($big)->members ],
	[ sort 1..4, 7..10 ],
);

is_deeply(
	[ sort $big->symmetric_difference($small)->members ],
	[ sort 1..4, 7..10 ],
);

is_deeply(
	[ sort $big->grep(sub { $_ % 2 == 0 })->members ],
	[ sort 6, 8, 10 ],
);

is_deeply(
	[ sort $big->map(sub { $_ % 3 })->members ],
	[ sort 0, 1, 2 ],
);

is_deeply(
	[ sort $big->map(sub { ($_ % 3, $_ + 10) })->members ],
	[ sort 0, 1, 2, 15, 16, 17, 18, 19, 20 ],
);

is_deeply(
	[ $big->part(sub { $_ % 2 }) ],
	[ set(6, 8, 10), set(5, 7, 9) ],
);

done_testing;

