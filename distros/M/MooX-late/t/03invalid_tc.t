=head1 PURPOSE

Check that we get error messages about unrecognisable type constraints.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;

$@ = undef;
ok !eval q {
# line 1 "embedded"
	package Foo;
	use Moo;
	use MooX::late;
	has foo => (is => 'ro', isa => 'X Y Z', required => 0);
	1;
};

like(
	$@,
	qr{^Unexpected tail on type expression:  Y Z},
	'error message looks ok',
);

done_testing;
