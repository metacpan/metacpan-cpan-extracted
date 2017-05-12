=head1 PURPOSE

Test C<set_is_number>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 10;
use Number::Natural::SetTheory qw/set_is_number/;

ok(
	set_is_number([], 0),
	'Empty set is zero',
	);
	
ok(
	!set_is_number(['x'], 0),
	'Random arrayref is not zero',
	);
	
ok(
	set_is_number([[]], 1),
	'Set containing empty set is one',
	);
	
ok(
	set_is_number([[],[[]]], 2),
	'Set containing zero and one is two',
	);

ok(
	set_is_number([[], [[]], [[],[[]]]], 3),
	'Set containing zero, one and two is three',
	);

ok(
	set_is_number([[[]], [], [[],[[]]]], 3),
	'Order does not matter - I',
	);

ok(
	set_is_number([[[]], [[],[[]]], []], 3),
	'Order does not matter - II',
	);

ok(
	set_is_number([[[],[[]]], [[]], []], 3),
	'Order does not matter - III',
	);

ok(
	set_is_number([[[],[[]]], [], [[]]], 3),
	'Order does not matter - IV',
	);

ok(
	set_is_number([[], [[],[[]]], [[]]], 3),
	'Order does not matter - V',
	);

