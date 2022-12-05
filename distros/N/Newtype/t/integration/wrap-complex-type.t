=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Newtype> can wrap a complex type.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

use Types::Common -types;

my $ComplexNumbersType;
BEGIN {
	$ComplexNumbersType = ArrayRef
		->of( Int )
		->create_child_type( type_default => sub { [ 1, 2, 3 ] } )
		->plus_coercions( Int, q{ [$_] } );
}

use Newtype MyNumbersType => { inner => $ComplexNumbersType };

my $n = to_MyNumbersType( 7 );
is( $n->INNER, [ 7 ], 'coercion worked' );
is( [ @$n ], [ 7 ], 'overloading worked' );

$n->reset;

is( $n->INNER, [ 1, 2, 3 ], 'reset worked' );

done_testing;
