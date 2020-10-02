=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Operable works in functional style.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use 5.008009;
use strict;
use warnings;
use Test::More;
use Sub::Operable 'subop';

# f($x) = $x ** 2
#
my $f = subop { $_ ** 2 };

# g($x) = 2 * $x
#
my $g = subop { 2 * $_ };

# h($x) = f($x) + g($x) + 3
#
my $h = $f + $g + 3;

# h(10) = f(10) + g(10) + 3
#       = 100   + 20    + 3
#       = 123
#
is( $h->(10), 123, 'composition with binary operators' );

# (-h)(10) = -(h(10))
#
is( (-$h)->(10), -123, 'composition with prefix operators' );

# m($x) = g( f($x) )
#
my $m = $g->($f);

# m(10) = g( f(10) )
#       = g(100)
#       = 200
#
is( $m->(10), 200, 'functions of functions' );

# n($x) = f( g($x) )
#
my $n = $f->($g);

# n(10) = f( g(10) )
#       = f(20)
#       = 400
#
is( $n->(10), 400, 'functions of functions, other way around' );

# p($x) = n($x) / m($x)
#
my $p = $n / $m;

# p(10) = n(10) / m(10)
#       = 400 / 200
#       = 2
is( $p->(10), 2, 'most complex thing' );

done_testing;

