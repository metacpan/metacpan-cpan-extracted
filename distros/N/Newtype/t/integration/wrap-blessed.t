=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Newtype> can wrap blessed objects properly.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

BEGIN {
	package Local::Foo;
	use Moo;
	has [ 'abc', 'xyz' ] => ( is => 'rw' );
};

BEGIN {
	package Local::Bar;
	use Moo;
	use Newtype MyFoo => {
		inner   => 'Local::Foo',
		methods => { sum => sub { my $s = shift; $s->abc + $s->xyz } },
	};
	has def => (
		is => 'rw',
		isa => MyFoo(),
		coerce => 1,
	);
	sub bleh {
		MyFoo( 'Local::Foo'->new );
	}
};

my $bar = 'Local::Bar'->new(
	def => 'Local::Foo'->new(
		abc => 123,
		xyz => 789,
	),
);

is( $bar->def->abc, 123, 'delegated method' );
is( $bar->def->sum, 123 + 789, 'extra method' );
isa_ok( $bar->def, 'Local::Bar::Newtype::MyFoo' );
isa_ok( $bar->def, 'Local::Foo' );

isa_ok( $bar->bleh, 'Local::Bar::Newtype::MyFoo' );
isa_ok( $bar->bleh, 'Local::Foo' );

ok Local::Bar::is_MyFoo( $bar->bleh );
Local::Bar::assert_MyFoo( $bar->bleh );
isa_ok( Local::Bar::to_MyFoo( 'Local::Foo'->new ), 'Local::Bar::Newtype::MyFoo' );

done_testing;
