use strict;
use warnings;

=encoding utf8

=head1 UNICODE

☘ ☠ X<$x=>☃

X<$y=>  ☘ 

X<$z=>"☘"

=cut

use Test::More tests => 3;
use Pod::Constant qw($x $y $z);

is( $x, '☃' );
is( $y, '☘' );
is( $z, '☘' );
