=head1 PURPOSE

Tests L<Scalar::Accessors::LikeHash::JSON> class; and by extension tests
L<Scalar::Accessors::LikeHash> role.

=head1 CAVEATS

Test is skipped if L<JSON> module is unavailable.

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
	JSON   => 2.00,
};

use t::Accessors;

my $class = 'Scalar::Accessors::LikeHash::JSON';

subtest(
	"Accessors provided by $class work as expected",
	t::Accessors->checker($class),
);

my $j = $class->new;
$j->store(xxx => [1,2,3]);
is(
	$$j,
	'{"xxx":[1,2,3]}',
	"$class stores its internals as correctly formatted JSON",
);

done_testing;
