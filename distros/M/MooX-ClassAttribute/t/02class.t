=head1 PURPOSE

Test C<class_has> in classes.

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

{
	package Foo;
	use Moo;
	use MooX::ClassAttribute;
	class_has foo => ( is => 'rw' );
}

Foo->foo(42);
is(Foo->foo, 42);

{
	package Bar;
	use Moo;
	use MooX::ClassAttribute;
	class_has bar => ( is => 'rw', default => sub { "Elephant" } );
}

is(Bar->bar, "Elephant");

SKIP:
{
	skip "this test requires Moo 1.002000", 1 if Moo->VERSION < 1.002000;
	
	{
		package Baz;
		use Moo;
		use MooX::ClassAttribute;
		extends 'Bar';
		class_has baz => ( is => 'rw', default => "Monkey" );
	}

	is(Baz->baz, "Monkey");
};

diag "*** The Moose awakes!!" if $INC{'Moose.pm'};
done_testing;
