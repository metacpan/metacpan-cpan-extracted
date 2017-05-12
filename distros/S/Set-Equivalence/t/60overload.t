=pod

=encoding utf-8

=head1 PURPOSE

Test overloading for sets.

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

my $small = set( 1..6 );
my $big   = set( 5..10 );

is( set(1).'', '(1)', '""' );
is( $big * $small, set( 5..6 ), '*' );
is( $big + $small, set( 1..10 ), '+' );
is( $big - $small, set( 7..10 ), '-' );
is( $big % $small, set( 1..4, 7..10 ), '%' );
ok( $big == set(10,5,7,9,6,8), '==' );
ok( not($big == set(10)), 'not ==' );
ok( $big != $small, '!=' );
ok( not($big != $big), 'not !=' );
ok( $big eq set(10,5,7,9,6,8), 'eq' );
ok( not($big eq set(10)), 'not eq' );
ok( $big ne $small, 'ne' );
ok( not($big ne $big), 'not ne' );

ok( set(1..6) <= $small, '<=' );
ok( set(1..3) <= $small, '<=' );
ok( not($big <= $small), 'not <=' );
ok( not(set(1..6) < $small), 'not <' );
ok( set(1..3) < $small, '<' );
ok( not($big < $small), 'not <' );

ok( $small >= set(1..6), '>=' );
ok( $small >= set(1..3), '>=' );
ok( not($small >= $big), 'not >=' );
ok( not($small > set(1..6)), 'not >' );
ok( $small > set(1..3), '>' );
ok( not($small > $big), 'not >' );

is( scalar(@$small), 6, '@{}' );

ok( $small, 'bool' );
ok( set(), 'bool' );

done_testing;
