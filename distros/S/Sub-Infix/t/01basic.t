=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Infix compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 10;
use Test::Fatal;

use Sub::Infix;

BEGIN {
	*plus  = infix { $_[0] + $_[1] };
	*minus = infix { $_[0] - $_[1] };
}

is(
	2 |plus| 3,
	5,
	'2 |plus| 3 == 5',
);

is(
	2 |minus| 3,
	-1,
	'2 |minus| 3 == -1',
);

is(
	2 /plus/ 3,
	5,
	'2 /plus/ 3 == 5',
);

is(
	2 /minus/ 3,
	-1,
	'2 /minus/ 3 == -1',
);

is(
	2 <<plus>> 3,
	5,
	'2 <<plus>> 3 == 5',
);

is(
	2 <<minus>> 3,
	-1,
	'2 <<minus>> 3 == -1',
);

is(
	plus->(2, 3),
	5,
	'plus->(2,3) == 5',
);

is(
	minus->(2, 3),
	-1,
	'minus->(2,3) == -1',
);

like(
	exception { 2 /plus| 3 },
	qr{^\/infix\| not supported},
	'exception for weird usage (A)',
);

like(
	exception { 2 >>plus<< 3 },
	qr{^\>\>infix\<\< not supported},
	'exception for weird usage (B)',
);
