=pod

=encoding utf-8

=head1 PURPOSE

Test that Object::Adhoc is capable of recursion.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Object::Adhoc;

my $t1 = object {
	foo => { bar => { baz => { quux => 42 } } },
	bar => 666,
	baz => [ 999, { foo => 111 }, [ { bar => 222 } ], [ [ { baz => 333 } ] ] ],
	zzz => \ { foo => 'xxx' },
	fun => sub { return { foo => 42 } },
}, recurse => 3;

is $t1->foo->bar->baz->{quux}, 42;
is ref($t1->foo->bar->baz), 'HASH';
is $t1->baz->[0], 999;
is $t1->baz->[1]->foo, 111;
is $t1->baz->[2][0]->{bar}, 222;
is $t1->baz->[3][0][0]->{baz}, 333;
is ref($t1->baz->[3][0][0]), 'HASH';
is ${ $t1->zzz }->foo, 'xxx';
isnt ref($t1->fun->()), 'HASH';
is $t1->fun->()->foo, 42;

done_testing;
