=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_new >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;
use Test::Requires { Moo   => '1.000000' };
use Test::Requires { curry => '0' };

use Object::Util;

{
	package Foo;
	use Moo;
	has foo => (is => "ro");
}

my $factory = sub { "Foo"->new(foo => $_[0]+2) };

{
	package FooMaker;
	use Moo;
	use overload (
		'&{}'    => sub { shift->curry::weak::make_foo },
		fallback => 1,
	);
	has foo_base => (is => "ro");
	sub make_foo {
		my $self = shift;
		Foo->new(foo => $self->foo_base + $_[0]);
	}
}

is(
	Foo->$_new(foo => 42)->foo,
	42,
	'$class->$_new',
);

is(
	$factory->$_new(40)->foo,
	42,
	'$coderef->$_new',
);

my $factory2 = FooMaker->new(foo_base => 12);
is(
	$factory2->$_new(30)->foo,
	42,
	'$object->$_new',
);

like(
	exception { my $x = []; $x->$_new },
	qr/^Invocant is not a coderef/,
	'$ref->$_new (exception)',
);

done_testing;

