=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSConstructor compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings;

{
	package Foo;
	use Moose;
	has xyz => (is => "ro", required => 1);
	sub DEMOLISH { 0 }
}

{
	package Bar;
	use Moose;
	use MooseX::XSConstructor;
	extends "Foo";
	has abc => (
		is      => "ro",
		isa     => 'Int',
		lazy    => 0,
		builder => '_build_abc',
	);
	sub _build_abc { 123 }
}

for ( 0 .. 1 ) {

	if ( $_ ) {
		$_->meta->make_immutable( inline_constructor => 0, inline_destructor => 0 )
			for qw/ Foo Bar /;
	}


	ok(
		!MooseX::XSConstructor::is_xs(Foo->can('new')),
		'Foo::new is not XS'
	);

	ok(
		!MooseX::XSConstructor::is_xs(Foo->can('DESTROY')),
		'Foo::DESTROY is not XS'
	);

	ok(
		MooseX::XSConstructor::is_xs(Bar->can('new')),
		'Bar::new is XS'
	);

	ok(
		MooseX::XSConstructor::is_xs(Bar->can('DESTROY')),
		'Bar::DESTROY is XS'
	);

	is_deeply(
		Bar->new(xyz => 123),
		bless( { xyz => 123, abc => 123 }, "Bar" ),
		"is deeply"
	);

	like(
		exception { Bar->new },
		qr/required/,
		'required stuff works'
	);

	like(
		exception { Bar->new(abc => "x", xyz => 123) },
		qr/type constraint/,
		'type constraint works'
	);
}

done_testing;
