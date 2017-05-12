=head1 PURPOSE

Tests L<Scalar::Accessors::LikeHash::Sereal> class; and by extension tests
L<Scalar::Accessors::LikeHash> role.

=head1 CAVEATS

Test is skipped if L<Sereal> module is unavailable.

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
use Test::Requires {
	Sereal => 0.260,
};

use t::Accessors;

my $class = 'Scalar::Accessors::LikeHash::Sereal';

subtest(
	"Accessors provided by $class work as expected",
	t::Accessors->checker($class),
);

my $j = $class->new;
$j->store(xxx => [1,2,3]);
is(
	$$j,
	"=srl\x{0001}\x{0000}(*\x{0001}cxxx(+\x{0003}\x{0001}\x{0002}\x{0003}",
	"$class stores its internals as correctly formatted Sereal",
);

done_testing;
