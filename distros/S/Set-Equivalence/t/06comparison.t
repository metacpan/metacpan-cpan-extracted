=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence's comparison methods work.

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

use Set::Equivalence qw(set);

my $all   = set(1..10);
my $other = set(1..10);
my $small = set(1..5);
my $big   = set(6..10);

ok($all->equal($all));
ok($all->equal($other));
ok($other->equal($all));
ok($small->equal($small));
ok($big->equal($big));

ok($all->not_equal($small));
ok($all->not_equal($big));
ok($small->not_equal($all));
ok($big->not_equal($all));
ok($small->not_equal($big));
ok($big->not_equal($small));

ok($all->superset($small));
ok($all->superset($big));
ok($all->superset($all));

ok($small->subset($all));
ok($big->subset($all));
ok($all->subset($all));

ok($all->proper_superset($small));
ok($all->proper_superset($big));
ok(!$all->proper_superset($all));

ok($small->proper_subset($all));
ok($big->proper_subset($all));
ok(!$all->proper_subset($all));

ok(!$big->subset($small));
ok(!$big->proper_subset($small));
ok(!$big->superset($small));
ok(!$big->proper_superset($small));

ok($big->is_disjoint($small));
ok($small->is_disjoint($big));
ok(!$big->is_disjoint($all));
ok(!$all->is_disjoint($big));

done_testing;

