=pod

=encoding utf-8

=head1 PURPOSE

Test coercions from Types::Sets.

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

use Set::Equivalence qw(typed_set);
use Types::Standard -types;
use Types::Set -types;

my $Rounded = Int->plus_coercions(Num, q{ int($_) });

is_deeply(
	[ sort +(Set[$Rounded])->coerce( [1, 2, 3.14159] )->members ],
	[ 1 .. 3 ],
);

is_deeply(
	[ sort +(MutableSet[$Rounded])->coerce( [1, 2, 3.14159] )->members ],
	[ 1 .. 3 ],
);

my $i = (ImmutableSet[$Rounded])->coerce( typed_set(Defined, 1, 2, 3.14159) );
is_deeply(
	[ sort $i->members ],
	[ 1 .. 3 ],
);
ok($i->is_immutable);
is($i->type_constraint, $Rounded);

done_testing;

