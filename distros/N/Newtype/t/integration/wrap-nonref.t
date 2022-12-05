=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Newtype> can wrap non-references properly.

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
	use Newtype MyNum => { inner => PositiveNum };
	has def => (
		is => 'rw',
		isa => MyNum(),
		coerce => 1,
	);
	sub bleh {
		MyNum->new( 456 );
	}
};

my $bar = 'Local::Bar'->new(
	def => 123,
);

is( $bar->def, 123, 'overloading' );
isa_ok( $bar->def, 'Local::Bar::Newtype::MyNum' );

$bar->def->add( 1 );
is( $bar->def, 124, 'SHV mutator method' );

my $e = dies {
	$bar->def->add( -1_000 );
};
like $e, qr/Must be a positive number/;

my $num = Local::Bar::bleh();
isa_ok( $num, 'Local::Bar::Newtype::MyNum' );
ok( $num == 456 );

done_testing;
