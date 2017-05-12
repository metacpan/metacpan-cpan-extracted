use strict;
use warnings;

=head1 DESCRIPTION

X< $a = > 1

X<$b=> 3

X< $c=>4

X<   $d  = > 5

=cut

use Test::More tests => 4;
use Pod::Constant qw($a $b $c $d);

is($a, 1);
is($b, 3);
is($c, 4);
is($d, 5);
