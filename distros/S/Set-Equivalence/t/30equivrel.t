=pod

=encoding utf-8

=head1 PURPOSE

Test that custom equivalence relations work.

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

use Set::Equivalence qw();

my $set = 'Set::Equivalence'->new(
	members              => [qw/ Foo Bar FOO BAR foo bar baz /],
	equivalence_relation => sub { lc($_[0]) eq lc($_[1]) },
);

is($set->size, 3);
is_deeply(
	[ sort $set->members ],
	[ sort qw/ Foo Bar baz / ],
);

done_testing;
