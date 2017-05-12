=head1 PURPOSE

See if C<< coerce => 1 >> works.

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
use Test::Fatal;

use Types::Standard qw( Int Num );

my $Int = Int->plus_coercions( Num, q{int($_)} );

{
	package Foo;
	use Moo; use MooX::late;
	has attr => (is => 'ro', isa => $Int, coerce => 1);
}

is(
	Foo->new(attr => 3.14159)->attr,
	3,
);

#like(
#	exception {
#		package Bar;
#		use Moo; use MooX::late;
#		has attr => (is => 'ro', isa => $Int->no_coercions, coerce => 1);
#	},
#	qr{^Invalid coerce '1'},
#);

done_testing;
