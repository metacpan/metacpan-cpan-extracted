=head1 PURPOSE

Test C<set_to_number>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 6;
use Number::Natural::SetTheory qw/set_to_number/;

is(
	set_to_number([]),
	0,
	'Empty set is zero',
	);
	
ok(
	!defined set_to_number(['x']),
	'Random arrayref is not zero',
	);
	
is(
	set_to_number([[]]),
	1,
	'Set containing empty set is one',
	);
	
is(
	set_to_number([[],[[]]]),
	2,
	'Set containing zero and one is two',
	);

is(
	set_to_number([[], [[]], [[],[[]]]]),
	3,
	'Set containing zero, one and two is three',
	);

is(
	set_to_number([[[]], [], [[],[[]]]]),
	3,
	'Order does not matter - I',
	);

