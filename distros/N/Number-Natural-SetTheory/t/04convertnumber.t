=head1 PURPOSE

Test C<number_to_set>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 4;
use Number::Natural::SetTheory qw/number_to_set/;

is_deeply(
	number_to_set(0),
	[],
	'Empty set is zero',
	);
	
is_deeply(
	number_to_set(1),
	[[]],
	'Set containing empty set is one',
	);
	
is_deeply(
	number_to_set(2),
	[[],[[]]],
	'Set containing zero and one is two',
	);

is_deeply(
	number_to_set(3),
	[[], [[]], [[],[[]]]],
	'Set containing zero, one and two is three',
	);