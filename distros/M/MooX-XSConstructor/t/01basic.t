=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::XSConstructor compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

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
	use Moo;
	has xyz => (is => "ro", required => 1);
	sub DEMOLISH { 0 }
}

{
	package Bar;
	use Moo;
	use MooX::XSConstructor;
	extends "Foo";
	has abc => (
		is      => "ro",
		isa     => sub { $_[0] =~ /^[0-9]+$/ or die "not an integer" },
		lazy    => 0,
		builder => sub { 123 },
	);
}

ok(
	!MooX::XSConstructor::is_xs(\&Foo::new),
	'Foo::new is not XS'
);

ok(
	!MooX::XSConstructor::is_xs(\&Foo::DESTROY),
	'Foo::DESTROY is not XS'
);

ok(
	MooX::XSConstructor::is_xs(\&Bar::new),
	'Bar::new is XS'
);

ok(
	MooX::XSConstructor::is_xs(\&Bar::DESTROY),
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
	qr/not an integer/,
	'type constraint works'
);

done_testing;
