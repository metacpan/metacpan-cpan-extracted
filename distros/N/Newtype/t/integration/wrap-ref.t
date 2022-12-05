=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Newtype> can wrap non-blessed references properly.

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
	package Local::Bar;
	use Moo;
	use Types::Common -types;
	use Newtype MyHashRef => {
		inner   => HashRef[Int],
		methods => { sum => sub { my $s = shift; $s->{abc} + $s->{xyz} } },
	};
	has def => (
		is => 'rw',
		isa => MyHashRef(),
		coerce => 1,
	);
	sub bleh {
		MyHashRef( {} );
	}
};

my $bar = 'Local::Bar'->new(
	def => {
		abc => 123,
		xyz => 789,
	},
);

is( $bar->def->get( 'abc' ), 123, 'SHV method' );
is( $bar->def->{'xyz'}, 789, 'overloading' );
is( $bar->def->sum, 123 + 789, 'extra method' );
isa_ok( $bar->def, 'Local::Bar::Newtype::MyHashRef' );

$bar->def->set( 'xxx' => 999 );
is( $bar->def->get( 'xxx' ), 999, 'SHV setter method' );

my $e = dies {
	$bar->def->set( 'xxx' => 'yyy' );
};
like $e, qr/did not pass type constraint/;

done_testing;
