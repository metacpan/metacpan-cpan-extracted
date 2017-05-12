=pod

=encoding utf-8

=head1 PURPOSE

Test that Set::Equivalence::_Tie works.

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

my $set = set(1..5);

is_deeply(
	[ sort @$set ],
	[ sort 1..5 ],
	'@$set',
);

push @$set, 1..10;

is_deeply(
	[ sort @$set ],
	[ sort 1..10 ],
	'push @$set',
);

unshift @$set, 1..20;

is_deeply(
	[ sort @$set ],
	[ sort 1..20 ],
	'unshift @$set',
);

my $elem = pop(@$set);
cmp_ok($elem, '<', 21, 'pop @$set ... below upper limit');
cmp_ok($elem, '>', 0, '... above lower limit');
is($set->size, 19, '... reduces size of set');
is(scalar(@$set), 19, '... reflected in scalar(@$set)');

is_deeply(
	[ sort $elem, @$set ],
	[ sort 1..20 ],
	'... seems to have altered $set correctly',
);

my $elem2 = shift(@$set);
cmp_ok($elem2, '<', 21, 'shift @$set ... below upper limit');
cmp_ok($elem2, '>', 0, '... above lower limit');
is($set->size, 18, '... reduces size of set');
is(scalar(@$set), 18, '... reflected in scalar(@$set)');

is_deeply(
	[ sort $elem, $elem2, @$set ],
	[ sort 1..20 ],
	'... seems to have altered $set correctly',
);

@$set = ();
ok($set->is_null, '@$set = ()');

done_testing;
