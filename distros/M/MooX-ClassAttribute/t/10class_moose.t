=head1 PURPOSE

Test C<class_has> in classes, with inflation to Moose.

Check introspection.

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
eval { require Moose } or plan skip_all => 'need Moose';
is(Foo->foo, 42);

{
	package Bar;
	use Moo;
	use MooX::ClassAttribute;
	class_has bar => ( is => 'rw', default => sub { "Elephant" } );
}

is(Bar->bar, "Elephant");

unless (eval { require MooseX::ClassAttribute })
{
	diag "no MooseX::ClassAttribute; no further tests";
	done_testing;
	exit;
}

can_ok(Foo->meta, 'get_class_attribute');
ok(Foo->meta->get_class_attribute('foo'));
ok(not Foo->meta->get_class_attribute('foo')->has_default);

can_ok(Bar->meta, 'get_class_attribute');
ok(Bar->meta->get_class_attribute('bar'));
ok(Bar->meta->get_class_attribute('bar')->has_default);

done_testing;
