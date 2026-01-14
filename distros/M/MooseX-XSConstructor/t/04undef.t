=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::XSConstructor works with MooseX::UndefTolerant.

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
use Test::Requires 'MooseX::UndefTolerant';

{
	package Foo;
	use Moose;
	use MooseX::UndefTolerant;
	use MooseX::XSConstructor;
	has foo => ( is => 'ro', isa => 'Str', predicate => 'has_foo' );
}

for ( 0 .. 1 ) {

	if ( $_ ) {
		$_->meta->make_immutable( inline_constructor => 0, inline_destructor => 0 )
			for qw/ Foo /;
	}

	ok(
		MooseX::XSConstructor::is_xs(Foo->can('new')),
		'Foo::new is XS'
	);

	is_deeply(
		Foo->new( foo => 66 ),
		bless( { foo => 66 }, 'Foo' ),
		'is_deeply',
	);

	my $o = Foo->new( foo => undef );
	is_deeply(
		$o,
		bless( {}, 'Foo' ),
		'is_deeply',
	);
	
	ok( ! $o->has_foo, 'predicate' );
}

done_testing;