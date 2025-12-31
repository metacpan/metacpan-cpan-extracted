=pod

=encoding utf-8

=head1 PURPOSE

Tests that L<Newtype> can do fancy coercions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

use Types::Common 'Num';
use Newtype
	DegC => {
		inner  => Num,
		coerce => [ DegF => sub { DegC( ( $_ - 32 ) / 1.8 ) } ],
	},
	DegF => {
		inner  => Num,
		coerce => [ DegC => sub { DegF( ( $_ * 1.8 ) + 32 ) } ],
	};

my $degc = to_DegC( DegF(356) );

ok "$degc", "180";

done_testing;
