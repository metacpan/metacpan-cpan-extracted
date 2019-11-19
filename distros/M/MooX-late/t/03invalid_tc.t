=head1 PURPOSE

Check that we get error messages about unrecognisable type constraints.

Test skipped on Perl < 5.14 because idek.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires '5.014000';
use Test::Fatal;

my $e;
{
	package Foo;
	use Moo;
	use MooX::late;
	$e = ::exception {
		has foo => (is => 'ro', isa => 'X Y Z', required => 0);
	};
};

diag($e);

like(
	$e,
	qr{^Unexpected tail on type expression:  Y Z},
	'error message looks ok',
);

done_testing;
