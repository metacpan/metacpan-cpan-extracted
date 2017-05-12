=head1 PURPOSE

Test C<class_has> in roles.

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
	use Moo::Role;
	use MooX::ClassAttribute;
	class_has foo => ( is => 'rw' );
}

{
	package WithFoo;
	use Moo;
	with 'Foo';
}

WithFoo->foo(42);
is(WithFoo->foo, 42);

{
	package Bar;
	use Moo::Role;
	use MooX::ClassAttribute;
	class_has bar => ( is => 'rw', default => sub { "$_[0] XYZ" } );
}

{
	package WithBar;
	use Moo;
	with 'Bar';
}

is(WithBar->bar, "WithBar XYZ");

diag "*** The Moose awakes!!" if $INC{'Moose.pm'};
done_testing;
